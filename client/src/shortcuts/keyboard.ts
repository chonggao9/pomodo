// 全局桌面级键盘快捷键交互系统

export interface ShortcutHandlers {
  onToggleTimer: () => void;
  onCloseAllOverlays: () => void;
  onSwitchTab: (tabKey: string) => void;
  onToggleFullscreen: () => void;
  onNewTask: () => void;
  onShowShortcutsHelp: () => void;
}

export class KeyboardShortcutManager {
  private handlers: ShortcutHandlers;
  private isEnabled = true;

  constructor(handlers: ShortcutHandlers) {
    this.handlers = handlers;
    this.bindEvents();
  }

  private isTyping(target: EventTarget | null): boolean {
    if (!target || !(target instanceof HTMLElement)) return false;
    const tagName = target.tagName.toLowerCase();
    return tagName === 'input' || tagName === 'textarea' || target.isContentEditable;
  }

  private bindEvents(): void {
    window.addEventListener('keydown', (e: KeyboardEvent) => {
      if (!this.isEnabled) return;

      const typing = this.isTyping(e.target);

      // Escape：无论是否在输入框，均允许一键关闭所有浮层/抽屉
      if (e.key === 'Escape') {
        this.handlers.onCloseAllOverlays();
        if (e.target instanceof HTMLElement) {
          e.target.blur();
        }
        return;
      }

      // 如果用户正在输入文本，不拦截常规按键
      if (typing) return;

      // Space: 专注钟 暂停 / 继续
      if (e.code === 'Space') {
        e.preventDefault();
        this.handlers.onToggleTimer();
        return;
      }

      // 数字键 1 ~ 4: 快速直达四大 Tab
      if (e.key === '1') {
        e.preventDefault();
        this.handlers.onSwitchTab('today');
        return;
      }
      if (e.key === '2') {
        e.preventDefault();
        this.handlers.onSwitchTab('pomo');
        return;
      }
      if (e.key === '3') {
        e.preventDefault();
        this.handlers.onSwitchTab('stats');
        return;
      }
      if (e.key === '4') {
        e.preventDefault();
        this.handlers.onSwitchTab('profile');
        return;
      }

      // 'F' / 'f': 全屏沉浸专注模式切换
      if (e.key.toLowerCase() === 'f') {
        e.preventDefault();
        this.handlers.onToggleFullscreen();
        return;
      }

      // 'N' / 'n': 新建待办抽屉展开
      if (e.key.toLowerCase() === 'n') {
        e.preventDefault();
        this.handlers.onNewTask();
        return;
      }

      // '?': 快捷键说明
      if (e.key === '?' || (e.shiftKey && e.key === '/')) {
        e.preventDefault();
        this.handlers.onShowShortcutsHelp();
        return;
      }
    });
  }

  public setEnabled(enabled: boolean): void {
    this.isEnabled = enabled;
  }
}
