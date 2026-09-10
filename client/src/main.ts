// PomoDo 客户端工程核心逻辑 (SQLite 3 驱动)
import './style.css';
import {
  SQLiteEngine,
  TaskRepository,
  PomodoroRepository,
  StatsRepository,
  type TaskEntity,
} from './db';
import { ProceduralAudioEngine, type NoiseType } from './audio/white_noise';
import { KeyboardShortcutManager } from './shortcuts/keyboard';

// 引擎与仓库实例
const engine = SQLiteEngine.getInstance();
const taskRepo = new TaskRepository();
const pomoRepo = new PomodoroRepository();
const statsRepo = new StatsRepository();
const audioEngine = ProceduralAudioEngine.getInstance();

// 离线白噪音状态
let activeNoiseType: NoiseType = 'rain';

// 当前专注目标状态
let currentFocusTaskId: string | null = null;
let currentFocusTaskTitle = '14:00 部门月度会议';
let currentFocusTaskPriority = 3;

// 番茄钟运行状态
let currentPomoMinutes = 25;
let currentBreakMinutes = 5;
let pomoRemainingSeconds = 25 * 60;
let pomoTimerInterval: number | null = null;
let pomoStartTime: string = new Date().toISOString();
let isPomoRunning = false;

// 外观与主题
export let currentGlobalAppearance: 'light' | 'dark' | 'auto' = 'light';
const appearanceModes: Array<'light' | 'dark' | 'auto'> = ['light', 'dark', 'auto'];
let appearanceIdx = 0;

const themeList = [
  { name: '马尔斯绿 (默认)', primary: '#008779', dark: '#006D62' },
  { name: '千草蓝 (文艺清爽)', primary: '#0984E3', dark: '#0652DD' },
  { name: '心想事橙 (温馨阳光)', primary: '#E67E22', dark: '#D35400' },
  { name: '新年红 (喜庆活力)', primary: '#B83227', dark: '#8E2017' },
];
let themeIdx = 0;

// 待办偏好配置
let currentIvyLimit = 5;
let currentTaskCompleteStyle = 'strike';

// 语言偏好
export let selectedLangCode = 'zh';
let selectedLangName = '简体中文 (默认)';

// -------------------------------------------------------------
// Toast 轻量通知
// -------------------------------------------------------------
export function showPomoToast(msg: string): void {
  let toast = document.getElementById('pomoToast');
  let text = document.getElementById('pomoToastText');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'pomoToast';
    toast.className = 'pomo-toast-toast';
    text = document.createElement('span');
    text.id = 'pomoToastText';
    toast.appendChild(text);
    const parent = document.querySelector('.phone-viewport') || document.body;
    parent.appendChild(toast);
  }
  if (text) text.textContent = msg;
  toast.classList.add('show');
  setTimeout(() => {
    toast?.classList.remove('show');
  }, 2400);
}

// -------------------------------------------------------------
// 数据库任务渲染与交互 (SQLite -> UI)
// -------------------------------------------------------------
function renderTasksFromDb(): void {
  const list = document.getElementById('taskStreamBox');
  if (!list) return;

  const tasks = taskRepo.getAllTasks();
  list.innerHTML = '';

  tasks.forEach((task) => {
    const isDone = task.status === 'completed';
    const card = document.createElement('div');
    card.id = `taskCard_${task.id}`;
    card.className = `pure-task-card ${isDone ? 'is-completed' : ''}`;
    card.onclick = () => toggleTask(task.id);

    const checkSvg = isDone
      ? '<svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="3.5"><polyline points="20 6 9 17 4 12"/></svg>'
      : '';

    card.innerHTML = `
      <div class="pure-checkbox ${isDone ? 'checked' : ''}" onclick="event.stopPropagation(); window.toggleTaskStrike('${task.id}')">
        ${checkSvg}
      </div>
      <div class="pure-task-body">
        <div class="pure-task-text">${escapeHtml(task.title)}</div>
        <div class="pure-task-meta">
          <span>⏰ ${task.due_date ? task.due_date : '今天'}</span>
          <span>·</span>
          <span class="meta-pill-sub">${task.workload === 'hard' ? '深度' : '日常'}</span>
        </div>
      </div>
      <div class="pure-ivy-num" style="display: flex; align-items: center; gap: 8px;">
        <span onclick="event.stopPropagation(); window.startFocusFromCard('${task.id}', '${escapeHtml(task.title)}', ${task.ivy_order}, event)" title="立即专注" style="cursor: pointer; font-size: 14px; opacity: 0.85; transition: transform 0.15s ease;">🍅</span>
        <span>${task.ivy_order}</span>
      </div>
    `;

    list.appendChild(card);
  });

  // 同步更新专注下拉候选列表
  updatePomoTaskDropdownList(tasks);
}

function updatePomoTaskDropdownList(tasks: TaskEntity[]): void {
  const dd = document.getElementById('pomoTaskDropdown');
  if (!dd) return;

  const pending = tasks.filter(t => t.status === 'pending');
  let html = `
    <div class="pomo-dropdown-item ${!currentFocusTaskId ? 'active' : ''}" id="pomoTaskOpt_free" onclick="window.selectPomoTask('', '自由专注 · 不关联待办', 0)">
      <span>🌿 自由专注 · 不关联待办</span>
      <span class="dropdown-check">✓</span>
    </div>
  `;

  pending.forEach(t => {
    const isCurrent = t.id === currentFocusTaskId;
    html += `
      <div class="pomo-dropdown-item ${isCurrent ? 'active' : ''}" id="pomoTaskOpt_${t.id}" onclick="window.selectPomoTask('${t.id}', '${escapeHtml(t.title)}', ${t.ivy_order})">
        <span>[${t.ivy_order}] ${escapeHtml(t.title)}</span>
        <span class="dropdown-check">${isCurrent ? '✓' : ''}</span>
      </div>
    `;
  });

  dd.innerHTML = html;
}

function escapeHtml(str: string): string {
  return str.replace(/[&<>'"]/g, tag => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  }[tag] || tag));
}

export function toggleTask(taskId: string): void {
  const updated = taskRepo.toggleTaskStatus(taskId);
  if (updated) {
    renderTasksFromDb();
    refreshStatsDisplay();
    if (updated.status === 'completed') {
      showPomoToast(`✅ 任务「${updated.title}」已划线完成！`);
    } else {
      showPomoToast(`↩️ 已恢复待办任务「${updated.title}」`);
    }
  }
}

export function submitQuickTask(): void {
  const input = document.getElementById('quickInputText') as HTMLInputElement | null;
  if (!input) return;
  const val = input.value.trim();
  if (!val) return;

  taskRepo.createTask({
    title: val,
    priority: 'P1',
    workload: 'easy',
  });

  input.value = '';
  renderTasksFromDb();
  refreshStatsDisplay();
  showPomoToast(`📋 艾利任务已安全持久化至 SQLite：${val}`);
}

export function handleQuickEnter(e: KeyboardEvent): void {
  if (e.key === 'Enter') {
    submitQuickTask();
  }
}

// -------------------------------------------------------------
// 方案 C 抽屉任务新建/编辑
// -------------------------------------------------------------
export function openDetailSheet(cardIdOrTitle?: string, title?: string, _priority?: number): void {
  const sheet = document.getElementById('pageDetailSheet');
  const titleInput = document.getElementById('sheetTaskTitle') as HTMLInputElement | null;

  if (titleInput) {
    titleInput.value = title || (typeof cardIdOrTitle === 'string' && !cardIdOrTitle.startsWith('taskCard_') ? cardIdOrTitle : '') || '';
  }

  sheet?.classList.add('sheet-open');
  document.getElementById('btnTabDetail')?.classList.add('active');
}

export function closeDetailSheet(): void {
  const sheet = document.getElementById('pageDetailSheet');
  sheet?.classList.remove('sheet-open');
  document.getElementById('btnTabDetail')?.classList.remove('active');
}

export function saveFromSheet(): void {
  const titleInput = document.getElementById('sheetTaskTitle') as HTMLInputElement | null;
  const noteInput = document.getElementById('sheetTaskNote') as HTMLTextAreaElement | null;
  const title = titleInput?.value.trim();

  if (title) {
    taskRepo.createTask({
      title,
      notes: noteInput?.value.trim() || undefined,
      priority: 'P1',
    });
    renderTasksFromDb();
    refreshStatsDisplay();
    showPomoToast(`✨ 详细待办已入列 SQLite：${title}`);
  }
  closeDetailSheet();
}

// -------------------------------------------------------------
// Tab 切换导航
// -------------------------------------------------------------
export function switchMobileTab(tabKey: string): void {
  document.querySelectorAll('.top-sub-tab').forEach(b => b.classList.remove('active'));
  document.querySelectorAll('.nav-tab-item').forEach(b => b.classList.remove('active-tab'));

  const pToday = document.getElementById('pageToday');
  const pPomo = document.getElementById('pagePomo');
  const pStats = document.getElementById('pageStats');
  const pProfile = document.getElementById('pageProfile');
  closeDetailSheet();

  if (pToday) pToday.style.display = 'none';
  if (pPomo) pPomo.style.display = 'none';
  if (pStats) pStats.style.display = 'none';
  if (pProfile) pProfile.style.display = 'none';

  if (tabKey === 'today') {
    if (pToday) pToday.style.display = 'flex';
    document.getElementById('btnTabToday')?.classList.add('active');
    document.getElementById('tabNavToday')?.classList.add('active-tab');
    renderTasksFromDb();
  } else if (tabKey === 'pomo') {
    if (pPomo) pPomo.style.display = 'flex';
    document.getElementById('btnTabPomo')?.classList.add('active');
    document.getElementById('tabNavPomo')?.classList.add('active-tab');
    updatePomoDisplay();
  } else if (tabKey === 'stats') {
    if (pStats) pStats.style.display = 'flex';
    document.getElementById('btnTabStats')?.classList.add('active');
    document.getElementById('tabNavStats')?.classList.add('active-tab');
    refreshStatsDisplay();
  } else if (tabKey === 'profile') {
    if (pProfile) pProfile.style.display = 'flex';
    document.getElementById('btnTabProfile')?.classList.add('active');
    document.getElementById('tabNavProfile')?.classList.add('active-tab');
    updateProfileHeroDisplay();
    refreshDatabaseMetrics();
  }
}

export function switchMainView(mode: string): void {
  document.querySelectorAll('.view-mode-btn').forEach(b => b.classList.remove('active'));
  const mobSec = document.getElementById('viewMobileSection');
  const webSec = document.getElementById('viewWebSection');
  const cmpSec = document.getElementById('viewCompareSection');

  if (mobSec) mobSec.style.display = 'none';
  if (webSec) webSec.style.display = 'none';
  if (cmpSec) cmpSec.style.display = 'none';

  if (mode === 'mobile') {
    if (mobSec) mobSec.style.display = 'flex';
    document.querySelectorAll('.view-mode-btn')[0]?.classList.add('active');
  } else if (mode === 'web') {
    if (webSec) webSec.style.display = 'flex';
    document.querySelectorAll('.view-mode-btn')[1]?.classList.add('active');
  } else if (mode === 'compare') {
    if (cmpSec) cmpSec.style.display = 'flex';
    document.querySelectorAll('.view-mode-btn')[2]?.classList.add('active');
  }
}

// -------------------------------------------------------------
// 番茄专注钟 (Dieter Rams 机械表盘与心流计时)
// -------------------------------------------------------------
function updatePomoDisplay(): void {
  const label = document.getElementById('currentPomoTaskLabel');
  if (label) {
    label.textContent = currentFocusTaskId ? `[${currentFocusTaskPriority}] ${currentFocusTaskTitle}` : currentFocusTaskTitle;
  }
}

export function startFocusFromCard(taskId: string, title: string, priority: number, event?: Event): void {
  if (event) event.stopPropagation();
  currentFocusTaskId = taskId;
  currentFocusTaskTitle = title;
  currentFocusTaskPriority = priority;
  updatePomoDisplay();
  switchMobileTab('pomo');
  showPomoToast(`🍅 已载入待办「${title}」，进入沉浸专注！`);
}

export function startFocusFromDetail(): void {
  const titleInput = document.getElementById('sheetTaskTitle') as HTMLInputElement | null;
  const title = titleInput?.value.trim() || currentFocusTaskTitle;
  currentFocusTaskTitle = title;
  updatePomoDisplay();
  closeDetailSheet();
  setTimeout(() => {
    switchMobileTab('pomo');
    showPomoToast(`🍅 已选定待办「${title}」，开始专注！`);
  }, 160);
}

export function togglePomoTaskDropdown(event?: Event): void {
  if (event) event.stopPropagation();
  const dd = document.getElementById('pomoTaskDropdown');
  const bubble = document.getElementById('pomoQuickDurationPicker');
  if (bubble) bubble.style.display = 'none';
  if (dd) {
    dd.style.display = dd.style.display === 'flex' ? 'none' : 'flex';
  }
}

export function selectPomoTask(taskId: string, title: string, priority: number): void {
  currentFocusTaskId = taskId || null;
  currentFocusTaskTitle = title;
  currentFocusTaskPriority = priority;
  updatePomoDisplay();

  const dd = document.getElementById('pomoTaskDropdown');
  if (dd) dd.style.display = 'none';
  showPomoToast(`🎯 已选定专注目标：${title}`);
}

export function togglePomoQuickDurationPicker(event?: Event): void {
  if (event) event.stopPropagation();
  const bubble = document.getElementById('pomoQuickDurationPicker');
  const dd = document.getElementById('pomoTaskDropdown');
  if (dd) dd.style.display = 'none';
  if (bubble) {
    bubble.style.display = bubble.style.display === 'flex' ? 'none' : 'flex';
  }
}

export function setQuickPomoMinutes(mins: number): void {
  currentPomoMinutes = mins;
  pomoRemainingSeconds = mins * 60;
  const digit = document.getElementById('pomoDigitDisplay');
  if (digit) digit.textContent = `${mins}:00`;
  const hint = document.getElementById('pomoSessionHint');
  if (hint) hint.textContent = `目标 ${mins} 分钟 · 点击时间快捷换时长`;

  document.querySelectorAll('#pomoQuickDurationPicker span').forEach(sp => {
    sp.classList.toggle('active', sp.textContent === `${mins}m`);
  });
  const bubble = document.getElementById('pomoQuickDurationPicker');
  if (bubble) bubble.style.display = 'none';
  showPomoToast(`⏱️ 专注时长已切换为 ${mins} 分钟`);
}

export function pausePomoTimer(): void {
  isPomoRunning = false;
  if (pomoTimerInterval) clearInterval(pomoTimerInterval);
  audioEngine.stop();

  const actionsRunning = document.getElementById('pomoActionsRunning');
  const actionsPaused = document.getElementById('pomoActionsPaused');
  if (actionsRunning) actionsRunning.style.display = 'none';
  if (actionsPaused) actionsPaused.style.display = 'flex';

  const badge = document.getElementById('pomoStatusBadge');
  if (badge) badge.innerHTML = '<span style="display:inline-block;width:6px;height:6px;border-radius:50%;background:#F59E0B;"></span> PAUSED';
  showPomoToast('⏸️ 专注已暂停，环境音已静音');
}

export function resumePomoTimer(): void {
  isPomoRunning = true;
  if (activeNoiseType !== 'none') {
    audioEngine.play(activeNoiseType);
  }

  const actionsPaused = document.getElementById('pomoActionsPaused');
  const actionsRunning = document.getElementById('pomoActionsRunning');
  if (actionsPaused) actionsPaused.style.display = 'none';
  if (actionsRunning) actionsRunning.style.display = 'flex';

  const badge = document.getElementById('pomoStatusBadge');
  if (badge) badge.innerHTML = '<span class="pomo-pulse-dot"></span> FOCUSING';
  showPomoToast('▶️ 专注已恢复，心流继续');
  runTimerLoop();
}

export function abandonPomoTimer(): void {
  isPomoRunning = false;
  if (pomoTimerInterval) clearInterval(pomoTimerInterval);
  audioEngine.stop();
  pomoRemainingSeconds = currentPomoMinutes * 60;

  const actionsPaused = document.getElementById('pomoActionsPaused');
  const actionsRunning = document.getElementById('pomoActionsRunning');
  if (actionsPaused) actionsPaused.style.display = 'none';
  if (actionsRunning) actionsRunning.style.display = 'flex';

  const digit = document.getElementById('pomoDigitDisplay');
  if (digit) digit.textContent = `${currentPomoMinutes}:00`;
  const badge = document.getElementById('pomoStatusBadge');
  if (badge) badge.innerHTML = '<span class="pomo-pulse-dot"></span> READY';

  // 记录放弃会话至 SQLite
  pomoRepo.recordSession({
    task_id: currentFocusTaskId,
    duration_minutes: Math.max(1, Math.round((currentPomoMinutes * 60 - pomoRemainingSeconds) / 60)),
    white_noise: activeNoiseType !== 'none' ? activeNoiseType : null,
    status: 'abandoned',
    started_at: pomoStartTime,
    ended_at: new Date().toISOString(),
  });

  showPomoToast('✕ 已放弃本次专注，时钟已重置为就绪状态');
}

export function completePomoTaskEarly(): void {
  isPomoRunning = false;
  if (pomoTimerInterval) clearInterval(pomoTimerInterval);
  audioEngine.stop();

  // 播放 528Hz 治愈禅音和弦完成提示音
  try {
    audioEngine.playCompletionChime();
  } catch (e) {
    console.warn('Chime playback error:', e);
  }

  const durationMins = Math.max(1, Math.round((currentPomoMinutes * 60 - pomoRemainingSeconds) / 60) || currentPomoMinutes);

  // 1. 持久化专注记录至 SQLite
  pomoRepo.recordSession({
    task_id: currentFocusTaskId,
    duration_minutes: durationMins,
    white_noise: activeNoiseType !== 'none' ? activeNoiseType : null,
    status: 'completed',
    started_at: pomoStartTime,
    ended_at: new Date().toISOString(),
  });

  // 2. 若关联了待办任务，则在 SQLite 中自动划线完成
  if (currentFocusTaskId) {
    const task = taskRepo.getTaskById(currentFocusTaskId);
    if (task && task.status === 'pending') {
      taskRepo.toggleTaskStatus(currentFocusTaskId);
    }
  }

  // 恢复时钟状态
  pomoRemainingSeconds = currentPomoMinutes * 60;
  const actionsPaused = document.getElementById('pomoActionsPaused');
  const actionsRunning = document.getElementById('pomoActionsRunning');
  if (actionsPaused) actionsPaused.style.display = 'none';
  if (actionsRunning) actionsRunning.style.display = 'flex';

  const digit = document.getElementById('pomoDigitDisplay');
  if (digit) digit.textContent = `${currentPomoMinutes}:00`;
  const badge = document.getElementById('pomoStatusBadge');
  if (badge) badge.innerHTML = '<span class="pomo-pulse-dot"></span> COMPLETED';

  renderTasksFromDb();
  refreshStatsDisplay();
  showPomoToast(`🔔 专注达成 (${durationMins}m)！已敲响禅钟并就地划线！`);

  setTimeout(() => {
    switchMobileTab('today');
  }, 900);
}

// -------------------------------------------------------------
// 离线自然环境白噪音选择器
// -------------------------------------------------------------
export function selectAmbientNoise(type: NoiseType): void {
  activeNoiseType = type;

  // 更新 UI 胶囊高亮
  const chips: Record<NoiseType, string> = {
    rain: 'chipNoise_rain',
    ocean: 'chipNoise_ocean',
    pink: 'chipNoise_pink',
    none: 'chipNoise_none',
  };

  const nameMap: Record<NoiseType, string> = {
    rain: '🌧️ 清脆自然雨幕',
    ocean: '🌊 潮汐呼吸海浪',
    pink: '☕ 舒缓粉红暖噪',
    none: '🔇 静音',
  };

  Object.entries(chips).forEach(([k, id]) => {
    const chip = document.getElementById(id);
    if (!chip) return;
    if (k === type) {
      chip.classList.add('active');
      if (type !== 'none' && !chip.querySelector('.sound-wave-bars')) {
        const wave = document.createElement('div');
        wave.className = 'sound-wave-bars';
        wave.innerHTML = '<span></span><span></span><span></span>';
        chip.prepend(wave);
      }
    } else {
      chip.classList.remove('active');
      chip.querySelector('.sound-wave-bars')?.remove();
    }
  });

  if (type === 'none') {
    audioEngine.stop();
    showPomoToast('🔇 已关闭环境白噪音');
  } else {
    audioEngine.play(type);
    showPomoToast(`🎧 已切换环境声：${nameMap[type]}`);
  }
}

// -------------------------------------------------------------
// 全屏沉浸专注模式 (Fullscreen Immersive Focus)
// -------------------------------------------------------------
export function toggleFullscreenFocus(): void {
  const vp = document.querySelector('.phone-viewport');
  if (!vp) return;

  const isFullscreen = vp.classList.toggle('fullscreen-immersive-mode');
  if (isFullscreen) {
    switchMobileTab('pomo');
    showPomoToast('⛶ 已进入全屏沉浸专注态 (按 Esc 或 F 退出)');
    if (document.documentElement.requestFullscreen && !document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
    }
  } else {
    showPomoToast('已退出全屏沉浸态');
    if (document.exitFullscreen && document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    }
  }
}

// -------------------------------------------------------------
// 桌面快捷键说明弹窗
// -------------------------------------------------------------
export function openShortcutsHelp(): void {
  document.getElementById('keyboardShortcutsOverlay')?.classList.add('show');
}

export function closeShortcutsHelp(): void {
  document.getElementById('keyboardShortcutsOverlay')?.classList.remove('show');
}

function runTimerLoop(): void {
  if (pomoTimerInterval) clearInterval(pomoTimerInterval);
  pomoStartTime = new Date().toISOString();

  pomoTimerInterval = window.setInterval(() => {
    if (!isPomoRunning) return;
    if (pomoRemainingSeconds > 0) {
      pomoRemainingSeconds--;
      const m = Math.floor(pomoRemainingSeconds / 60);
      const s = pomoRemainingSeconds % 60;
      const digit = document.getElementById('pomoDigitDisplay');
      if (digit) {
        digit.textContent = `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
      }
    } else {
      // 倒计时自然结束
      completePomoTaskEarly();
    }
  }, 1000);
}

// -------------------------------------------------------------
// Tab 3: 复盘看板数据聚合 (SQLite -> UI)
// -------------------------------------------------------------
function refreshStatsDisplay(): void {
  const stats = statsRepo.getOverviewStats();

  const completionRate = stats.totalTasks > 0
    ? Math.round((stats.completedTasks / stats.totalTasks) * 100)
    : 100;

  // 动态更新看板数值元素
  const ringText = document.getElementById('statsCompletionPercent');
  if (ringText) ringText.textContent = `${completionRate}%`;

  const doneCount = document.getElementById('statsDoneCount');
  if (doneCount) doneCount.textContent = `${stats.completedTasks}`;

  const todayFocus = document.getElementById('statsTodayFocus');
  if (todayFocus) todayFocus.textContent = `${stats.todayFocusMinutes}m`;

  const totalPomodoros = document.getElementById('statsTotalPomodoros');
  if (totalPomodoros) totalPomodoros.textContent = `${stats.totalPomodoros}`;
}

// -------------------------------------------------------------
// Tab 4: 本地个人档案与 SQLite 本地数据库中心
// -------------------------------------------------------------
let currentProfileNickname = localStorage.getItem('pomodo_profile_nickname') || 'Vy';
let currentProfileMotto = localStorage.getItem('pomodo_profile_motto') || '做完最重要的 3 件事再休息';
let currentProfileAvatar = localStorage.getItem('pomodo_profile_avatar') || 'sunset';

export function updateProfileHeroDisplay(): void {
  const nameEl = document.querySelector('.profile-username-text');
  if (nameEl) nameEl.textContent = currentProfileNickname;
  const metaEl = document.getElementById('profileNicknameMeta');
  if (metaEl) metaEl.textContent = `${currentProfileNickname} · 专注中`;
}

export function openProfileSheet(): void {
  const nickInput = document.getElementById('inputProfileNickname') as HTMLInputElement | null;
  const mottoInput = document.getElementById('inputProfileMotto') as HTMLInputElement | null;
  if (nickInput) nickInput.value = currentProfileNickname;
  if (mottoInput) mottoInput.value = currentProfileMotto;

  // 高亮选中头像
  document.querySelectorAll('.avatar-option-card').forEach(card => {
    card.classList.remove('active');
    (card as HTMLElement).style.border = '1px solid var(--border-light)';
    (card as HTMLElement).style.background = '#FFFFFF';
  });
  const activeCard = document.getElementById(`avatarOpt_${currentProfileAvatar}`);
  if (activeCard) {
    activeCard.classList.add('active');
    activeCard.style.border = '2px solid var(--theme-primary)';
    activeCard.style.background = 'var(--theme-subtle)';
  }

  document.getElementById('pageProfileSheet')?.classList.add('sheet-open');
}

export function closeProfileSheet(): void {
  document.getElementById('pageProfileSheet')?.classList.remove('sheet-open');
}

export function selectProfileAvatar(key: string, elem: HTMLElement): void {
  currentProfileAvatar = key;
  document.querySelectorAll('.avatar-option-card').forEach(c => {
    c.classList.remove('active');
    (c as HTMLElement).style.border = '1px solid var(--border-light)';
    (c as HTMLElement).style.background = '#FFFFFF';
  });
  elem.classList.add('active');
  elem.style.border = '2px solid var(--theme-primary)';
  elem.style.background = 'var(--theme-subtle)';
}

export function saveLocalProfile(): void {
  const nickInput = document.getElementById('inputProfileNickname') as HTMLInputElement | null;
  const mottoInput = document.getElementById('inputProfileMotto') as HTMLInputElement | null;
  if (nickInput && nickInput.value.trim()) {
    currentProfileNickname = nickInput.value.trim();
    localStorage.setItem('pomodo_profile_nickname', currentProfileNickname);
  }
  if (mottoInput && mottoInput.value.trim()) {
    currentProfileMotto = mottoInput.value.trim();
    localStorage.setItem('pomodo_profile_motto', currentProfileMotto);
  }
  localStorage.setItem('pomodo_profile_avatar', currentProfileAvatar);

  updateProfileHeroDisplay();
  showPomoToast(`✅ 本地个人档案已保存：${currentProfileNickname}`);
  closeProfileSheet();
}

export function openDatabaseCenterSheet(): void {
  refreshDatabaseMetrics();
  document.getElementById('pageDatabaseCenterSheet')?.classList.add('sheet-open');
}

export function closeDatabaseCenterSheet(): void {
  document.getElementById('pageDatabaseCenterSheet')?.classList.remove('sheet-open');
}

export function refreshDatabaseMetrics(): void {
  const metrics = engine.getDatabaseMetrics();

  const sizeEl = document.getElementById('dbMetricFileSize');
  if (sizeEl) sizeEl.textContent = `${metrics.fileSizeFormatted} (${metrics.fileSizeBytes} B)`;

  const integrityEl = document.getElementById('dbMetricIntegrity');
  if (integrityEl) {
    if (metrics.integrityStatus === 'ok') {
      integrityEl.textContent = 'OK (完整无损)';
      integrityEl.style.color = '#27AE60';
    } else {
      integrityEl.textContent = `异常 (${metrics.integrityStatus})`;
      integrityEl.style.color = '#E74C3C';
    }
  }

  const tasksEl = document.getElementById('dbMetricTasks');
  if (tasksEl) tasksEl.textContent = `${metrics.taskCount} 项 (${metrics.pendingTaskCount} 待办 / ${metrics.completedTaskCount} 完成)`;

  const sessionsEl = document.getElementById('dbMetricSessions');
  if (sessionsEl) sessionsEl.textContent = `${metrics.sessionCount} 次专注`;

  const subtasksEl = document.getElementById('dbMetricSubtasks');
  if (subtasksEl) subtasksEl.textContent = `${metrics.subtaskCount} 项`;

  const categoriesEl = document.getElementById('dbMetricCategories');
  if (categoriesEl) categoriesEl.textContent = `${metrics.categoryCount} 个`;

  const verEl = document.getElementById('dbMetricSchemaVer');
  if (verEl) verEl.textContent = `v${metrics.schemaVersion}`;

  const timeEl = document.getElementById('dbMetricMigratedTime');
  if (timeEl) {
    timeEl.textContent = metrics.schemaAppliedAt !== '-' 
      ? `生效于 ${metrics.schemaAppliedAt.slice(0, 10)}` 
      : '已自动对齐';
  }

  const rowMeta = document.getElementById('profileDbStatusMeta');
  if (rowMeta) {
    rowMeta.textContent = `SQLite 3 · ${metrics.fileSizeFormatted} · v${metrics.schemaVersion}`;
  }
}

export function exportLocalDbFile(): void {
  engine.downloadDatabaseFile(`pomodo_backup_${Date.now()}.db`);
  refreshDatabaseMetrics();
  showPomoToast('💾 真实 SQLite 3 物理数据库 (.db) 已成功导出并下载！');
}

export function importLocalDb(): void {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.db,.sqlite,.sqlite3';
  input.onchange = async () => {
    const file = input.files?.[0];
    if (!file) return;

    try {
      const buffer = await file.arrayBuffer();
      const binary = new Uint8Array(buffer);
      await engine.importBinary(binary);
      renderTasksFromDb();
      refreshStatsDisplay();
      refreshDatabaseMetrics();
      showPomoToast(`✅ 成功导入 SQLite 物理数据库：${file.name}，数据已无损还原！`);
      closeDatabaseCenterSheet();
    } catch (e) {
      alert(`导入 SQLite 数据库失败：${e instanceof Error ? e.message : String(e)}`);
    }
  };
  input.click();
}

export async function confirmResetDatabase(): Promise<void> {
  const confirmed = window.confirm(
    '⚠️ 危险操作提示：\n\n您确定要清空并重置本地 SQLite 数据库中的所有待办任务与专注记录吗？\n\n此操作不可撤销，建议在重置前先点击「导出真实 SQLite 数据库」进行本地冷备份。'
  );
  if (!confirmed) return;

  try {
    await engine.wipeAndResetDatabase();
    renderTasksFromDb();
    refreshStatsDisplay();
    refreshDatabaseMetrics();
    showPomoToast('🧹 本地数据库已重置归零！');
    closeDatabaseCenterSheet();
  } catch (err) {
    alert(`重置数据库失败：${err instanceof Error ? err.message : String(err)}`);
  }
}

// -------------------------------------------------------------
// 外观、主题与多语言
// -------------------------------------------------------------
export function setGlobalAppearance(mode: 'light' | 'dark' | 'auto'): void {
  currentGlobalAppearance = mode;
  document.querySelectorAll('.appearance-option').forEach(o => o.classList.remove('active'));

  const vp = document.querySelector('.phone-viewport');
  const pPomo = document.getElementById('pagePomo');

  let isDark = false;
  if (mode === 'light') {
    document.getElementById('modeLightBtn')?.classList.add('active');
    isDark = false;
  } else if (mode === 'dark') {
    document.getElementById('modeDarkBtn')?.classList.add('active');
    isDark = true;
  } else if (mode === 'auto') {
    document.getElementById('modeAutoBtn')?.classList.add('active');
    isDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  if (isDark) {
    vp?.classList.add('app-dark-mode');
    pPomo?.classList.add('pomo-dark-mode');
  } else {
    vp?.classList.remove('app-dark-mode');
    pPomo?.classList.remove('pomo-dark-mode');
  }

  const rowLabel = document.getElementById('rowAppearanceLabel');
  if (rowLabel) {
    const map = { light: '外观：浅色模式', dark: '外观：深色模式', auto: '外观：跟随系统' };
    rowLabel.textContent = map[mode] || '外观：浅色模式';
  }
}

export function cycleGlobalAppearance(): void {
  appearanceIdx = (appearanceIdx + 1) % appearanceModes.length;
  const nextMode = appearanceModes[appearanceIdx];
  setGlobalAppearance(nextMode);
}

export function applyTheme(primary: string, dark: string, elem?: HTMLElement): void {
  document.querySelectorAll('.theme-select-card').forEach(c => c.classList.remove('active'));
  if (elem) elem.classList.add('active');

  document.documentElement.style.setProperty('--theme-primary', primary);
  document.documentElement.style.setProperty('--theme-dark', dark);
  document.documentElement.style.setProperty('--theme-light', `${primary}20`);
  document.documentElement.style.setProperty('--theme-subtle', `${primary}12`);
  document.documentElement.style.setProperty('--theme-shadow', `${primary}40`);
}

export function cycleThemeColor(): void {
  themeIdx = (themeIdx + 1) % themeList.length;
  const t = themeList[themeIdx];
  applyTheme(t.primary, t.dark);
  const el = document.getElementById('rowThemeLabel');
  if (el) el.textContent = t.name;
}

export function openTaskRulesSheet(): void {
  document.getElementById('pageTaskRulesSheet')?.classList.add('sheet-open');
}
export function closeTaskRulesSheet(): void {
  document.getElementById('pageTaskRulesSheet')?.classList.remove('sheet-open');
}
export function setIvyLimit(limit: number, btn: HTMLElement): void {
  currentIvyLimit = limit;
  btn.parentElement?.querySelectorAll('button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  const disp = document.getElementById('taskLimitDisplay');
  if (disp) disp.textContent = `严格 ${limit} 项`;
}
export function setTaskCompleteStyle(style: string, btn: HTMLElement): void {
  currentTaskCompleteStyle = style;
  btn.parentElement?.querySelectorAll('button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}
export function saveTaskRules(): void {
  const meta = document.getElementById('profileTaskRulesMeta');
  const styleText = currentTaskCompleteStyle === 'strike' ? '就地划线' : '底部归档';
  if (meta) meta.textContent = `艾利 1~${currentIvyLimit} 排序 · ${styleText}`;
  showPomoToast(`✅ 待办偏好已保存：每日艾利 1~${currentIvyLimit} · ${styleText}`);
  closeTaskRulesSheet();
}

export function openPomoRulesSheet(): void {
  document.getElementById('pagePomoRulesSheet')?.classList.add('sheet-open');
}
export function closePomoRulesSheet(): void {
  document.getElementById('pagePomoRulesSheet')?.classList.remove('sheet-open');
}
export function setPomoTargetMinutes(mins: number, btn: HTMLElement): void {
  currentPomoMinutes = mins;
  btn.parentElement?.querySelectorAll('button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  const disp = document.getElementById('pomoDurationDisplay');
  if (disp) disp.textContent = `${mins} 分钟`;
  const digit = document.getElementById('pomoDigitDisplay');
  if (digit) digit.textContent = `${mins}:00`;
}
export function setPomoBreak(shortMin: number, longMin: number, btn: HTMLElement): void {
  currentBreakMinutes = shortMin;
  btn.parentElement?.querySelectorAll('button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  const disp = document.getElementById('pomoBreakDisplay');
  if (disp) disp.textContent = `短休 ${shortMin}m · 长休 ${longMin}m`;
}
export function savePomoRules(): void {
  const meta = document.getElementById('profilePomoRulesMeta');
  if (meta) meta.textContent = `${currentPomoMinutes}m 专注 · ${currentBreakMinutes}m 短休`;
  showPomoToast(`🍅 番茄钟配置已更新：单次专注 ${currentPomoMinutes} 分钟`);
  closePomoRulesSheet();
}

export function openLanguageSheet(): void {
  document.getElementById('pageLanguageSheet')?.classList.add('sheet-open');
}
export function closeLanguageSheet(): void {
  document.getElementById('pageLanguageSheet')?.classList.remove('sheet-open');
}
export function selectLanguage(code: string, name: string): void {
  selectedLangCode = code;
  selectedLangName = name;
  ['system', 'zh', 'en'].forEach(k => {
    const opt = document.getElementById(`langOpt_${k}`);
    const chk = document.getElementById(`langCheck_${k}`);
    if (opt) {
      if (k === code) {
        opt.style.borderColor = 'var(--theme-primary)';
        opt.style.background = 'var(--theme-subtle)';
      } else {
        opt.style.borderColor = 'var(--border-light)';
        opt.style.background = '#FFFFFF';
      }
    }
    if (chk) chk.textContent = k === code ? '✓' : '';
  });
}
export function saveLanguageSetting(): void {
  const meta = document.getElementById('profileLanguageMeta');
  if (meta) meta.textContent = selectedLangName;
  showPomoToast(`🌐 系统语言已成功切换为：${selectedLangName}`);
  closeLanguageSheet();
}

export function openPrivacySheet(): void {
  document.getElementById('pagePrivacySheet')?.classList.add('sheet-open');
}
export function closePrivacySheet(): void {
  document.getElementById('pagePrivacySheet')?.classList.remove('sheet-open');
}

export function openProfileSheetHandler(): void {
  openProfileSheet();
}
export function closeProfileSheetHandler(): void {
  closeProfileSheet();
}
export function openDatabaseCenterSheetHandler(): void {
  openDatabaseCenterSheet();
}
export function closeDatabaseCenterSheetHandler(): void {
  closeDatabaseCenterSheet();
}

export function contactSupportEmail(): void {
  const email = 'chonggao9@gmail.com';
  if (navigator.clipboard && navigator.clipboard.writeText) {
    navigator.clipboard.writeText(email).catch(() => {});
  }
  showPomoToast(`✉️ 已复制官方反馈邮箱：${email}，正打开邮件客户端...`);
  setTimeout(() => {
    window.location.href = `mailto:${email}?subject=PomoDo%20%E7%94%A8%E6%88%B7%E5%8F%8D%E9%A6%88%E4%B8%8E%E5%BB%BA%E8%AE%AE`;
  }, 300);
}

export function showBadgeDetail(title: string, desc: string, isUnlocked: boolean): void {
  const statusIcon = isUnlocked ? '🏆' : '🔒';
  showPomoToast(`${statusIcon} 【${title}】${desc}`);
}

// -------------------------------------------------------------
// 挂载到全局 Window 对象，保障所有 HTML 内联 onclick 顺畅调用
// -------------------------------------------------------------
const globalApi = {
  switchMobileTab,
  switchMainView,
  toggleTaskStrike: toggleTask,
  toggleTask,
  submitQuickTask,
  handleQuickEnter,
  openDetailSheet,
  closeDetailSheet,
  saveFromSheet,
  startFocusFromCard,
  startFocusFromDetail,
  togglePomoTaskDropdown,
  selectPomoTask,
  cycleNextTaskFocus: togglePomoTaskDropdown,
  togglePomoQuickDurationPicker,
  setQuickPomoMinutes,
  pausePomoTimer,
  resumePomoTimer,
  abandonPomoTimer,
  completePomoTaskEarly,
  openTaskRulesSheet,
  closeTaskRulesSheet,
  setIvyLimit,
  setTaskCompleteStyle,
  saveTaskRules,
  openPomoRulesSheet,
  closePomoRulesSheet,
  setPomoTargetMinutes,
  setPomoBreak,
  savePomoRules,
  openLanguageSheet,
  closeLanguageSheet,
  selectLanguage,
  saveLanguageSetting,
  openPrivacySheet,
  closePrivacySheet,
  openProfileSheet,
  closeProfileSheet,
  selectProfileAvatar,
  saveLocalProfile,
  openDatabaseCenterSheet,
  closeDatabaseCenterSheet,
  refreshDatabaseMetrics,
  confirmResetDatabase,
  contactSupportEmail,
  showBadgeDetail,
  showPomoToast,
  exportLocalDbFile,
  importLocalDb,
  cycleGlobalAppearance,
  setGlobalAppearance,
  cycleThemeColor,
  applyTheme,
  selectAmbientNoise,
  toggleFullscreenFocus,
  openShortcutsHelp,
  closeShortcutsHelp,
};

Object.assign(window, globalApi);

// -------------------------------------------------------------
// 全局键盘快捷键与手势监听器
// -------------------------------------------------------------
function setupGlobalListeners(): void {
  // 1. 初始化桌面级键盘快捷键
  new KeyboardShortcutManager({
    onToggleTimer: () => {
      if (isPomoRunning) {
        pausePomoTimer();
      } else {
        resumePomoTimer();
      }
    },
    onCloseAllOverlays: () => {
      closeDetailSheet();
      closeProfileSheet();
      closeDatabaseCenterSheet();
      closeTaskRulesSheet();
      closePomoRulesSheet();
      closeLanguageSheet();
      closePrivacySheet();
      closeShortcutsHelp();
      const dd = document.getElementById('pomoTaskDropdown');
      if (dd) dd.style.display = 'none';
      const bubble = document.getElementById('pomoQuickDurationPicker');
      if (bubble) bubble.style.display = 'none';
      const vp = document.querySelector('.phone-viewport');
      if (vp?.classList.contains('fullscreen-immersive-mode')) {
        toggleFullscreenFocus();
      }
    },
    onSwitchTab: (tabKey) => {
      switchMobileTab(tabKey);
    },
    onToggleFullscreen: () => {
      toggleFullscreenFocus();
    },
    onNewTask: () => {
      openDetailSheet();
    },
    onShowShortcutsHelp: () => {
      openShortcutsHelp();
    },
  });

  // 2. 点击外部自动收起浮层
  document.addEventListener('click', (e) => {
    const target = e.target as HTMLElement | null;
    const dd = document.getElementById('pomoTaskDropdown');
    const bubble = document.getElementById('pomoQuickDurationPicker');

    if (dd && dd.style.display === 'flex' && !dd.contains(target) && !document.getElementById('pomoTargetPill')?.contains(target)) {
      dd.style.display = 'none';
    }
    if (bubble && bubble.style.display === 'flex' && !bubble.contains(target) && target !== document.getElementById('pomoDigitDisplay')) {
      bubble.style.display = 'none';
    }
  });

  // 3. iOS 物理阻尼下滑关闭抽屉
  document.querySelectorAll('.screen-view-detail').forEach((sheet) => {
    const panel = sheet.querySelector('.white-sheet-panel') as HTMLElement | null;
    if (!panel) return;
    let startY = 0;
    let currentY = 0;
    let isDragging = false;

    panel.addEventListener('touchstart', (e: TouchEvent) => {
      if (panel.scrollTop > 0) return;
      startY = e.touches[0].clientY;
      isDragging = true;
      panel.style.transition = 'none';
    }, { passive: true });

    panel.addEventListener('touchmove', (e: TouchEvent) => {
      if (!isDragging) return;
      currentY = e.touches[0].clientY;
      const deltaY = currentY - startY;
      if (deltaY > 0) {
        panel.style.transform = `translateY(${deltaY * 0.75}px)`;
      }
    }, { passive: true });

    panel.addEventListener('touchend', () => {
      if (!isDragging) return;
      isDragging = false;
      panel.style.transition = 'transform var(--dur-drawer) var(--ease-drawer)';
      const deltaY = currentY - startY;
      if (deltaY > 70) {
        sheet.classList.remove('sheet-open');
        panel.style.transform = '';
      } else {
        panel.style.transform = 'translateY(0)';
      }
    }, { passive: true });
  });
}

// -------------------------------------------------------------
// 应用主入口启动 (SQLite 初始化与数据种子灌入)
// -------------------------------------------------------------
async function bootstrapApp(): Promise<void> {
  console.info('🚀 Initializing PomoDo SQLite 3 Engine...');
  try {
    await engine.init();
    console.info('✅ SQLite 3 Engine Initialized with Schema Migrations.');

    // 若数据库中无任务，写入艾利 1~3 初始种子任务
    const existing = taskRepo.getAllTasks();
    if (existing.length === 0) {
      taskRepo.createTask({ title: '早起晨跑与拉伸', priority: 'P1', workload: 'easy' });
      taskRepo.createTask({ title: '与赵总吃中饭', priority: 'P2', workload: 'easy' });
      taskRepo.createTask({ title: '14:00 部门月度会议', priority: 'P3', workload: 'medium' });
    }

    setupGlobalListeners();
    renderTasksFromDb();
    refreshStatsDisplay();
    updateProfileHeroDisplay();
    refreshDatabaseMetrics();
    console.info('🎉 PomoDo Application Ready (100% Local-First SQLite).');
  } catch (err) {
    console.error('Failed to initialize SQLite database:', err);
    showPomoToast('⚠️ SQLite 初始化异常，请检查控制台');
  }
}

// 启动
bootstrapApp();
