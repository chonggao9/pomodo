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

  // 快捷获取
  static AppStrings of(BuildContext context) {
    final local = Localizations.localeOf(context);
    return AppStrings(local);
  }

  // 导航
  String get tabToday => isZh ? '今日' : 'Today';
  String get tabFocus => isZh ? '专注' : 'Focus';
  String get tabStats => isZh ? '复盘' : 'Stats';
  String get tabMine => isZh ? '我的' : 'Mine';

  // 徽章
  String get myBadges => isZh ? '我的徽章' : 'My Badges';
  String get badgeTimeMaster => isZh ? '时间掌控者' : 'Time Master';
  String get badgeFocusKing => isZh ? '专注魔王' : 'Focus King';
  String get badgePomoTycoon => isZh ? '番茄富翁' : 'Pomo Tycoon';
  String get badgeNightOwl => isZh ? '夜行侠' : 'Night Owl';

  // 个人中心菜单
  String get localProfile => isZh ? '本地个人档案' : 'Local Profile';
  String get dbCenter => isZh ? 'SQLite 本地数据库中心' : 'SQLite Database Center';
  String get listCategories => isZh ? '工作清单与分类管理' : 'Lists & Categories';
  String get personalization => isZh ? '个性化' : 'Personalization';
  String get basicSettings => isZh ? '基本设置' : 'Basic Settings';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get themeAndStyle => isZh ? '主题色与风格' : 'Theme & Style';
  String get taskSettings => isZh ? '待办与清单设置' : 'Task & List Settings';
  String get focusSettings => isZh ? '专注与番茄设置' : 'Focus & Pomodoro Settings';
  String get language => isZh ? '语言 / Language' : 'Language';
  String get checkUpdate => isZh ? '检查版本更新' : 'Check for Updates';

  // 外观设置
  String get modeLight => isZh ? '浅色模式' : 'Light Mode';
  String get modeDark => isZh ? '深邃暗雅 (墨绿黑曜)' : 'Dark Mode (Obsidian)';
  String get modeSystem => isZh ? '跟随系统' : 'System Default';

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

  // 通用
  String get cancel => isZh ? '取消' : 'Cancel';
  String get save => isZh ? '保存修改' : 'Save Changes';
  String get confirm => isZh ? '确定' : 'Confirm';
  String get successSaved => isZh ? '设置已保存' : 'Settings saved';
}
