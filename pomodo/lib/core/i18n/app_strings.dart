import 'package:flutter/material.dart';

enum AppLanguage {
  system,
  zh,
  en,
}

class AppStrings {
  final Locale locale;
  final bool isZh;

  AppStrings(this.locale) : isZh = locale.languageCode.toLowerCase() == 'zh';

  static AppStrings of(dynamic contextOrLang) {
    if (contextOrLang is BuildContext) {
      try {
        final local = Localizations.localeOf(contextOrLang);
        return AppStrings(local);
      } catch (_) {
        return AppStrings(const Locale('zh'));
      }
    } else if (contextOrLang is Locale) {
      return AppStrings(contextOrLang);
    } else if (contextOrLang is String) {
      return AppStrings(Locale(contextOrLang));
    }
    return AppStrings(const Locale('zh'));
  }

  // ================= 导航栏 (Navigation) =================
  String get tabToday => isZh ? '今日' : 'Today';
  String get tabFocus => isZh ? '专注' : 'Focus';
  String get tabStats => isZh ? '复盘' : 'Stats';
  String get tabMine => isZh ? '我的' : 'Settings';

  // ================= 日期与周历格式化 (Date & Week Strip) =================
  List<String> get weekDays => isZh
      ? const ['一', '二', '三', '四', '五', '六', '日']
      : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  String formatFullDate(DateTime date) {
    if (isZh) {
      const weekdaysZh = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
      return '${date.month}月${date.day}日 ${weekdaysZh[date.weekday - 1]}';
    } else {
      const weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      const monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdaysEn[date.weekday - 1]}, ${monthsEn[date.month - 1]} ${date.day}';
    }
  }

  // ================= 1. 今日待办 (Today Page) =================
  String get todayTitle => isZh ? '今日待办' : 'Today';
  String dayTasksTitle(int day) => isZh ? '$day日待办' : 'Tasks for Day $day';
  String get backToToday => isZh ? '回今天' : 'Today';
  String tasksCount(int count) => isZh ? '$count 个待办事项' : (count == 1 ? '1 task' : '$count tasks');
  String get allCompleted => isZh ? '今天的所有任务都已完成' : 'All tasks completed for today';
  String get enjoyCalm => isZh ? '享受内心的从容与专注' : 'Enjoy your calm and focused day';
  String noTasksDate(int month, int day) => isZh ? '$month月$day日 暂无日程任务' : 'No tasks scheduled';
  String get planTasksHint => isZh ? '在下方灵动输入框或点击 + 为该日规划要事' : 'Add tasks in the input bar or tap +';
  String get returnToTodayBtn => isZh ? '返回今日待办' : 'Back to Today';
  String get quickAddHint => isZh ? '+ 快速记录待办，按 Enter 入列...' : '+ Quick add task, press Enter...';
  String get focusAction => isZh ? '专注' : 'Focus';

  // 手势与快捷操作
  String get swipeToComplete => isZh ? '标记完成' : 'Complete';
  String get swipeToUncomplete => isZh ? '恢复待办' : 'Undo Done';
  String get swipeToDelete => isZh ? '删除任务' : 'Delete';
  String get undo => isZh ? '撤销' : 'Undo';
  String taskDeletedMsg(String title) => isZh ? '已删除任务「$title」' : 'Task "$title" deleted';

  // 艾利容量防爆缓冲池
  String get coreFocusTitle => isZh ? '今日核心要务' : 'Core Focus';
  String get bufferPoolTitle => isZh ? '候补任务池' : 'Buffer Pool';
  String bufferCount(int count) => isZh ? '$count 项候补' : '$count in buffer';
  String get bufferTip => isZh ? '专注击破上方要务后，再聚焦候补任务' : 'Finish core tasks first to maintain pure flow';
  String get completedSectionTitle => isZh ? '今日已达成' : 'Completed';

  // 分类与步骤
  String get categoryAll => isZh ? '全部' : 'All';
  String subtaskProgress(int done, int total) => isZh ? '$done/$total 步骤' : '$done/$total steps';

  // ================= 2. 沉浸专注 (Pomodoro Page) =================
  String get deepFocusTitle => isZh ? '沉浸专注' : 'Deep Focus';
  String get deepFocus => deepFocusTitle;
  String get deepFocusHeader => 'DEEP FOCUS';
  String get pureFlowTitle => isZh ? '自由专注' : 'Pure Flow';
  String get freeFocus => pureFlowTitle;
  String get focusingStatus => isZh ? '进行中' : 'Focusing';
  String get focusing => focusingStatus;
  String get pausedStatus => isZh ? '已暂停' : 'Paused';
  String get paused => pausedStatus;
  String get readyStatus => isZh ? '待命就绪' : 'Ready';
  String get ready => readyStatus;
  String get startFocus => isZh ? '开始专注' : 'Start Focus';
  String get pauseFocus => isZh ? '暂停专注' : 'Pause Focus';
  String get resumeFocus => isZh ? '继续专注' : 'Resume';
  String get cancelFocus => isZh ? '放弃' : 'Cancel';
  String get abandonReset => isZh ? '放弃重置' : 'Abandon & Reset';
  String get completeEarly => isZh ? '提前完成并划线' : 'Complete Early';
  String get earlyComplete => completeEarly;
  String get completeTask => isZh ? '达成划线' : 'Complete & Strike';
  String get linkTask => isZh ? '关联待办' : 'Link Task';
  String get linkTaskSheetTitle => isZh ? '选择关联待办' : 'Select Task to Focus';
  String get noTaskPureFlow => isZh ? '无关联任务（纯粹心流）' : 'No task (Pure flow)';
  String get soundScapes => isZh ? '自然有机声景 (无缝循环)' : 'Nature Soundscapes (Seamless Loop)';
  String get ambientNoiseTitle => soundScapes;
  String get noiseRain => isZh ? '窗台夜雨' : 'Window Rain';
  String get rain => noiseRain;
  String get noiseRainDesc => isZh ? '淅沥沥雨声 · 降噪安宁' : 'Gentle rain & tranquility';
  String get noiseWaves => isZh ? '深海潮汐' : 'Ocean Waves';
  String get ocean => noiseWaves;
  String get noiseWavesDesc => isZh ? '澎湃低频浪涌 · 深度思考' : 'Deep waves & deep thought';
  String get noiseCampfire => isZh ? '夜色篝火' : 'Night Campfire';
  String get campfire => noiseCampfire;
  String get noiseCampfireDesc => isZh ? '微弱柴火爆裂 · 温暖陪伴' : 'Crackling fire & cozy warmth';
  String get noiseOff => isZh ? '静音模式' : 'Mute';
  String get mute => noiseOff;
  String get noiseOffDesc => isZh ? '纯净静音 · 专注思考' : 'Silence & pure focus';
  String get playing => isZh ? '播放中' : 'Playing';
  String get auditioning => isZh ? '试听中' : 'Testing';
  String get audition => isZh ? '试听' : 'Preview';
  String get focusAccomplished => isZh ? '专注达成' : 'Focus accomplished';
  String get taskArchived => isZh ? '已就地划线归档！' : 'is completed & archived!';
  String pomoCompleteMsg(int minutes, String taskTitle) => isZh
      ? '专注达成（已记录 $minutes 分钟）！任务「$taskTitle」已就地划线归档！'
      : 'Focus accomplished ($minutes min)! Task "$taskTitle" is marked done!';

  // ================= 3. 复盘看板 (Stats Page) =================
  String get reviewTitle => isZh ? '复盘看板' : 'Performance & Review';
  String get statsReview => reviewTitle;
  String get reviewHeader => 'PERFORMANCE & REVIEW';
  String get completionRate => isZh ? '任务完成率' : 'Completion Rate';
  String get totalFocusHours => isZh ? '专注总时长' : 'Total Focus';
  String get totalFocusTime => totalFocusHours;
  String get pomoCycles => isZh ? '番茄时段' : 'Pomodoro Cycles';
  String get pomodoroPeriods => pomoCycles;
  String get validCycles => isZh ? '有效专注周期' : 'Effective cycles';
  String get pendingTasks => isZh ? '待办存量' : 'Pending Tasks';
  String get pendingStock => pendingTasks;
  String get inProgressToday => isZh ? '今日进行中' : 'In progress today';
  String get todayOngoing => inProgressToday;
  String get ivyDistribution => isZh ? '艾利优先级完成分布' : 'Ivy Lee Priority Completion';
  String get ivyLeeDistribution => ivyDistribution;
  String get ivyLeeRule => 'Ivy Lee 1~5';
  String get p1Desc => isZh ? 'P1 最高优先 (率先击破)' : 'P1 Top Priority (Strike First)';
  String get p2Desc => isZh ? 'P2 核心要务 (保持心流)' : 'P2 Core Focus (Maintain Flow)';
  String get p3Desc => isZh ? 'P3 次要跟进 (稳健推进)' : 'P3 Secondary (Steady Progress)';
  String get recentSessions => isZh ? '最近专注流水 (SQLite 自持)' : 'Recent Sessions (SQLite)';
  String get noSessions => isZh ? '暂无专注流水记录' : 'No focus sessions recorded yet';
  String get minutesAccumulated => isZh ? '分钟累计' : 'mins total';
  String get minutesTotal => minutesAccumulated;
  String get itemsUnit => isZh ? '项' : 'items';
  String get items => itemsUnit;
  String get hoursUnit => isZh ? '小时' : 'h';
  String get focusSession => isZh ? '专注时段' : 'Focus Session';

  // ================= 4. 任务属性详情抽屉 (Task Detail Sheet) =================
  String get sheetCreateTitle => isZh ? '新建待办事项' : 'New Task';
  String get sheetEditTitle => isZh ? '编辑待办事项' : 'Edit Task';
  String get titlePlaceholder => isZh ? '输入待办事项名称...' : 'Task title...';
  String get notesPlaceholder => isZh ? '添加补充描述或备注...' : 'Add notes or description...';
  String get selectListTitle => isZh ? '选择所属清单' : 'Select List';
  String get createListBtn => isZh ? '新建清单' : 'New List';
  String get noListsPrompt => isZh ? '暂无清单分类，点击右上角新建' : 'No custom lists yet, tap + to create';
  String get createCategoryTitle => isZh ? '新建清单分类' : 'New List Category';
  String get categoryNameHint => isZh ? '如：阅读学习、备考、家居' : 'e.g. Reading, Work, Personal';
  String get createAndSelectBtn => isZh ? '创建并选择' : 'Create & Select';
  String get defaultCategoryName => isZh ? '工作与工程' : 'Work & Projects';
  String get dueDateLabel => isZh ? '截止日期' : 'Due Date';
  String get choiceToday => isZh ? '今天' : 'Today';
  String get choiceTomorrow => isZh ? '明天' : 'Tomorrow';
  String get choicePickDate => isZh ? '选择日期' : 'Pick Date';
  String get choiceNoDate => isZh ? '没有日期' : 'No Date';
  String get priorityIvyLabel => isZh ? '艾利顺位 (Ivy Lee Priority)' : 'Ivy Lee Priority';
  String get workloadEstimateLabel => isZh ? '预估难度与番茄估时' : 'Estimated Workload';
  String get workloadEasy => isZh ? '一般 (1~2个番茄)' : 'Easy (1-2 pomos)';
  String get workloadMedium => isZh ? '中等难度 (3~4个)' : 'Medium (3-4 pomos)';
  String get workloadHard => isZh ? '较高难度 (5个+番茄)' : 'Hard (5+ pomos)';
  String get subtasksLabel => isZh ? '拆分子任务' : 'Subtasks';
  String get addSubtaskHint => isZh ? '添加步骤/子任务...' : 'Add step / subtask...';
  String get saveToLocalBtn => isZh ? '保存到本地' : 'Save to SQLite';
  String get startFocusNowBtn => isZh ? '开启专注' : 'Start Focus';
  String get deleteTaskConfirm => isZh ? '确定删除此任务吗？' : 'Delete this task?';
  String get deleteBtn => isZh ? '删除' : 'Delete';

  // ================= 5. 我的 / 设置 (Profile & Settings) =================
  String get localProfile => isZh ? '本地个人档案' : 'Local Profile';
  String get dbCenter => isZh ? 'SQLite 本地数据库中心' : 'SQLite Database Center';
  String get listCategories => isZh ? '工作清单与分类管理' : 'Lists & Categories';
  String get personalization => isZh ? '个性化' : 'Personalization';
  String get basicSettings => isZh ? '基本设置' : 'Basic Settings';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get themeAndStyle => isZh ? '主题色与风格' : 'Theme Color & Style';
  String get taskSettings => isZh ? '待办与清单设置' : 'Task & List Settings';
  String get focusSettings => isZh ? '专注与番茄设置' : 'Focus & Pomodoro Settings';
  String get language => isZh ? '语言 / Language' : 'Language';
  String get checkUpdate => isZh ? '检查版本更新' : 'Check for Updates';

  // 外观设置
  String get modeLight => isZh ? '浅色模式' : 'Light Mode';
  String get modeDark => isZh ? '深邃暗雅 (墨绿黑曜)' : 'Dark Mode (Obsidian)';
  String get modeSystem => isZh ? '跟随系统' : 'System Default';
  String get appearanceSubtitle => isZh ? '界面外观模式 (即切即生效)' : 'Appearance Theme Mode';

  // 主题色与风格 (方案 A)
  String get themeColorSubtitle => isZh ? '选择应用强调色 · 全局组件实时生效' : 'Choose primary accent color for UI';
  String get themeMarsGreen => isZh ? '马尔斯绿 (经典)' : 'Marrs Green (Classic)';
  String get themeMarsGreenDesc => isZh ? 'Things 3 纯净与自然专注' : 'Things 3 inspired & calm';
  String get themeOceanBlue => isZh ? '晴空深蓝' : 'Ocean Blue';
  String get themeOceanBlueDesc => isZh ? '开朗广阔 · 逻辑清晰' : 'Vibrant & clear focus';
  String get themeLavender => isZh ? '丁香微紫' : 'Lavender Purple';
  String get themeLavenderDesc => isZh ? '艺术典雅 · 灵动心流' : 'Creative & elegant flow';
  String get themeAmberOrange => isZh ? '琥珀暖橙' : 'Amber Orange';
  String get themeAmberOrangeDesc => isZh ? '热情活力 · 激发动力' : 'Warm & high energy';
  String get themeObsidianBlack => isZh ? '黑曜极简' : 'Obsidian Slate';
  String get themeObsidianBlackDesc => isZh ? '极简克制 · 极致深沉' : 'Minimalist & disciplined';

  // 待办设置
  String get dailyFocusLimit => isZh ? '每日艾利核心容量' : 'Daily Focus Limit';
  String get completionBehavior => isZh ? '任务完成行为' : 'Completion Behavior';
  String get keepInPlace => isZh ? '就地划线保留 (设计推荐)' : 'Strike-through in place';
  String get moveToBottom => isZh ? '划线并沉底' : 'Move to bottom';
  String get hideCompleted => isZh ? '隐藏归档' : 'Hide completed';
  String get rolloverStrategy => isZh ? '未完成任务次日自动顺延' : 'Auto-rollover incomplete tasks';

  // 专注设置
  String get focusDuration => isZh ? '默认专注时长' : 'Focus Duration';
  String get breakDuration => isZh ? '短休时长' : 'Break Duration';
  String get defaultWhiteNoise => isZh ? '默认环境白噪音' : 'Default Ambient Sound';
  String get minutesUnit => isZh ? '分钟' : 'min';

  // 徽章
  String get myBadges => isZh ? '我的徽章' : 'My Badges';
  String get badgeTimeMaster => isZh ? '时间掌控者' : 'Time Master';
  String get badgeFocusKing => isZh ? '专注魔王' : 'Focus King';
  String get badgePomoTycoon => isZh ? '番茄富翁' : 'Pomo Tycoon';
  String get badgeNightOwl => isZh ? '夜行侠' : 'Night Owl';

  // 通用
  String get cancel => isZh ? '取消' : 'Cancel';
  String get save => isZh ? '保存修改' : 'Save Changes';
  String get confirm => isZh ? '确定' : 'Confirm';
  String get successSaved => isZh ? '设置已保存' : 'Settings saved';

  // 待办与番茄双向联动 (方案 B)
  String get focusingNow => isZh ? '专注中' : 'Focusing';
  String get focusCompletedDialogTitle => isZh ? '专注达成 🎉' : 'Focus Completed! 🎉';
  String get focusCompletedDialogDesc =>
      isZh ? '恭喜完成本轮深度专注，该任务是否已搞定？' : 'Great focus session! Is this task accomplished?';
  String get markTaskCompletedAction => isZh ? '达成目标 · 划线完成' : 'Done & Mark Completed';
  String get takeBreakAction => isZh ? '开始 5 分钟短休 ☕' : 'Take a 5m Break ☕';
  String get continueFocusAction => isZh ? '再来一个番茄 🔁' : 'Another Pomodoro 🔁';
  String get selectTaskToFocus => isZh ? '🎯 选择今日要务开始专注' : '🎯 Select Today\'s Task to Focus';
  String get selectTaskSheetTitle => isZh ? '选择专注目标' : 'Select Focus Task';
  String get restModeTitle => isZh ? '轻松短休 ☕' : 'Short Break ☕';
  String get restModeDesc => isZh ? '闭目深呼吸，放松双眼和肩膀' : 'Take a deep breath and stretch';
  String get taskPomoStat => isZh ? '累计专注' : 'Total Focused';

  // Things 3 双轨流 (方案 1)
  String get inboxTitle => isZh ? '收集箱' : 'Inbox';
  String get inboxEmpty => isZh ? '收集箱空空如也' : 'Inbox is Empty';
  String get inboxEmptyDesc => isZh ? '随时记录突发的想法、灵感与未排期杂务' : 'Capture any thoughts or unscheduled tasks here';
  String get moveToToday => isZh ? '安排到今天' : 'Move to Today';
  String get movedToTodayMsg => isZh ? '已安排至今日要务' : 'Scheduled to Today';
  String get allTasksDoneTitle => isZh ? '今日要务已全部达成！🎉' : 'All Done for Today! 🎉';
  String get allTasksDoneSubtitle => isZh ? '享受专注后的宁静，或从收集箱挑选新目标' : 'Enjoy your well-earned free time, or pick from Inbox';
  String get browseInbox => isZh ? '浏览收集箱' : 'Open Inbox';
  String get toggleCalendar => isZh ? '日程日历' : 'Calendar';
  String todayRemainingCount(int count) => isZh ? '还有 $count 项要务' : '$count remaining';
  String get todayAllDoneText => isZh ? '今日全部搞定' : 'All Accomplished';
  String get inboxAddHint => isZh ? '记录新灵感或备忘，按回车添加...' : 'Add thought or task, press enter...';

  // 复盘全面重构与 Logbook 归档 (方案 A)
  String get logbookTitle => isZh ? '历史达成归档' : 'Logbook Archive';
  String get logbookSubtitle =>
      isZh ? '查阅所有已攻克的关键要务与时间投入' : 'All completed tasks and focused investment';
  String get allTimeCompleted => isZh ? '累计达成' : 'Completed';
  String get searchCompletedTasks => isZh ? '搜索已完成事项...' : 'Search completed tasks...';
  String get noCompletedTasks => isZh ? '暂无归档事项' : 'No completed tasks yet';
  String get noCompletedTasksDesc =>
      isZh ? '今日完成后的小成就将安全沉淀在此' : 'Your completed accomplishments will be saved here';
  String get reopenTask => isZh ? '恢复为未完成' : 'Reopen Task';
  String get taskReopenedMsg => isZh ? '已将该任务恢复为进行中' : 'Task restored to active';
  String get dimensionToday => isZh ? '今日' : 'Today';
  String get dimensionWeek => isZh ? '本周' : 'This Week';
  String get dualRingsTitle => isZh ? '效能闭环' : 'Activity Rings';
  String get ringTaskRate => isZh ? '任务达成' : 'Tasks Done';
  String get ringFocusRate => isZh ? '专注目标' : 'Focus Goal';
  String get dailyFocusGoal => isZh ? '每日目标 60m' : 'Daily Goal 60m';
  String get weeklyFocusGoal => isZh ? '本周目标 7h' : 'Weekly Goal 7h';
  String get categoryTimeDist => isZh ? '时间投资分布' : 'Time by Category';
  String get noCategoryTimeData => isZh ? '所选周期内暂无专注沉淀' : 'No focus sessions recorded';
  String get uncategorized => isZh ? '未分类' : 'Uncategorized';
  String get highValueSessions => isZh ? '专注心流明细' : 'Focus Flow Records';
  String get today => isZh ? '今天' : 'Today';
  String get yesterday => isZh ? '昨天' : 'Yesterday';
  String get earlierThisWeek => isZh ? '本周较早' : 'Earlier this week';
  String get earlier => isZh ? '更早归档' : 'Earlier Archive';
  String get viewAllLogbook => isZh ? '查看完整归档' : 'View Full Logbook';

  // 待办与番茄全面联合处理 (生命周期闭环)
  String get sessionTooShort => isZh ? '专注不足 1 分钟，未计入统计' : 'Focus under 1 min, not recorded';
  String get taskCompletedAutoSettle => isZh ? '已自动结算本次专注并记录流水' : 'Focus auto-settled and recorded';
  String get focusConflictTitle => isZh ? '正在专注其他任务' : 'Another Focus in Progress';
  String focusConflictDesc(String title, int elapsed) => isZh
      ? '任务「$title」正在专注中（已进行 $elapsed 分钟），是否结算并切换？'
      : 'Task "$title" is focusing ($elapsed min elapsed). Settle and switch?';
  String get settleAndSwitch => isZh ? '结算并切换' : 'Settle & Switch';
  String get discardAndSwitch => isZh ? '放弃并切换' : 'Discard & Switch';
  String get continueCurrentFocus => isZh ? '继续当前专注' : 'Continue Current';
}
