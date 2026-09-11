import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_strings.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/profile_provider.dart';
import 'task_detail_sheet.dart';

/// 100% 像素级对齐设计稿的「今日待办」页面
/// 核心升级 (选项 3):
/// 1. Things 3 风格通透大标题 + 极简周历条 + 分类横向过滤胶囊条
/// 2. SliverReorderableList 长按拖拽调序，做实 Ivy Lee 1~5 真实顺位
/// 3. 滑动手势 (Dismissible & Haptics): 右滑原地划线/撤销，左滑删除带 4 秒可撤销 SnackBar
/// 4. 艾利容量防爆缓冲池: 超出每日上限自动隔离「今日核心要务」与「候补任务池」
/// 5. 子任务卡片微进度徽章: 动态感知步骤完成度
class TodayPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TodayPage({super.key, this.onNavigateTab});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final TextEditingController _quickTitleController = TextEditingController();
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  bool _bufferExpanded = true;
  bool _isCompletedExpanded = false; // 已完成任务默认收拢折叠，杜绝霸屏
  bool _showWeekCalendar = false; // 周历条默认收起，专注今日

  @override
  void dispose() {
    _quickTitleController.dispose();
    super.dispose();
  }

  void _quickAddSubmit(BuildContext context) {
    final text = _quickTitleController.text.trim();
    if (text.isEmpty) return;

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    final taskProv = context.read<TaskProvider>();
    taskProv.addTask(
      title: text,
      dueDate: dateStr, // 今日页面添加时明确归入所选日期
      categoryId: taskProv.selectedCategoryId,
    );
    _quickTitleController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isSelectedToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);
    final monthDayStr = strings.formatFullDate(_selectedDate);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBgPage : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Consumer2<TaskProvider, ProfileProvider>(
          builder: (context, taskProv, profileProv, child) {
            // 读取次日自动顺延与分类筛选
            final rawTasks = taskProv.tasksForDate(
              _selectedDate,
              autoRollover: profileProv.autoRollover,
            );

            // 拆分未完成与已完成项
            final pendingTasks = rawTasks.where((t) => !t.isCompleted).toList();
            final completedTasks = rawTasks.where((t) => t.isCompleted).toList();

            // 艾利核心容量限制 (默认 5 项)
            final dailyLimit = profileProv.dailyTaskLimit;
            final hasCapacitySplit = dailyLimit > 0 && pendingTasks.length > dailyLimit;

            final List<Task> corePendingTasks;
            final List<Task> bufferPendingTasks;

            if (hasCapacitySplit) {
              corePendingTasks = pendingTasks.sublist(0, dailyLimit);
              bufferPendingTasks = pendingTasks.sublist(dailyLimit);
            } else {
              corePendingTasks = pendingTasks;
              bufferPendingTasks = [];
            }

            final totalVisibleTasks = rawTasks.length;

            return Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // 1. Things 3 风格通透标题区
                    SliverToBoxAdapter(
                      child: Container(
                        color: isDark ? AppTheme.darkBgSurface : Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 顶栏：● POMODO 品牌标 + 右侧功能簇 (收集箱胶囊 + 日程展开)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'POMODO',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: primaryColor,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),

                                // 右侧功能簇：📥 收集箱徽章 + 📅 日程折叠按钮
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showInboxSheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(isDark ? 0.18 : 0.08),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('📥', style: TextStyle(fontSize: 12)),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${strings.inboxTitle} (${taskProv.inboxCount})',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => setState(() => _showWeekCalendar = !_showWeekCalendar),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: _showWeekCalendar
                                              ? primaryColor.withOpacity(isDark ? 0.25 : 0.15)
                                              : (isDark ? AppTheme.darkBgSurface : const Color(0xFFF1F5F9)),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: _showWeekCalendar
                                                ? primaryColor.withOpacity(0.5)
                                                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.calendar_month_rounded,
                                          size: 15,
                                          color: _showWeekCalendar
                                              ? primaryColor
                                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // 大标题：今日待办 (或 X日待办)
                            Row(
                              children: [
                                Text(
                                  isSelectedToday ? strings.todayTitle : strings.dayTasksTitle(_selectedDate.day),
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (!isSelectedToday) ...[
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () {
                                      final n = DateTime.now();
                                      setState(() => _selectedDate =
                                          DateTime(n.year, n.month, n.day));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: primaryColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.today_rounded,
                                              size: 12, color: primaryColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            strings.backToToday,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),

                            // 副标题：日期 · 待办数量与完成统计
                            Text(
                              '$monthDayStr · ${pendingTasks.isNotEmpty ? strings.todayRemainingCount(pendingTasks.length) : (completedTasks.isNotEmpty ? strings.todayAllDoneText : '暂无待办')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Things 3 风格极简周历条 (按需展开)
                    if (_showWeekCalendar)
                      SliverToBoxAdapter(
                        child: _buildWeekStrip(taskProv, isDark, primaryColor, strings, profileProv.autoRollover),
                      ),

                    // 3. 清单分类横向滑动胶囊条 (Category Filter Strip)
                    SliverToBoxAdapter(
                      child: _buildCategoryFilterStrip(taskProv, isDark, primaryColor, strings),
                    ),

                    // 4. 任务流列表
                    if (taskProv.isLoading)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: primaryColor),
                        ),
                      )
                    else if (totalVisibleTasks == 0)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelectedToday
                                    ? Icons.spa_outlined
                                    : Icons.event_note_outlined,
                                size: 52,
                                color: (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)).withOpacity(0.4),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSelectedToday
                                    ? strings.allCompleted
                                    : strings.noTasksDate(_selectedDate.month, _selectedDate.day),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.darkTextMain : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isSelectedToday
                                    ? strings.enjoyCalm
                                    : strings.planTasksHint,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                                ),
                              ),
                              if (taskProv.inboxCount > 0) ...[
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  onPressed: () => _showInboxSheet(context),
                                  icon: const Text('📥', style: TextStyle(fontSize: 14)),
                                  label: Text(
                                    '${strings.browseInbox} (${taskProv.inboxCount})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ],
                              if (!isSelectedToday) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final n = DateTime.now();
                                    setState(() => _selectedDate =
                                        DateTime(n.year, n.month, n.day));
                                  },
                                  icon: Icon(Icons.arrow_back_rounded,
                                      size: 14, color: primaryColor),
                                  label: Text(
                                    strings.returnToTodayBtn,
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // === 情况 1：今日未完成已全数搞定 -> 展现 Things 3 All Done 沉浸成就空状态 ===
                      if (pendingTasks.isEmpty && completedTasks.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                  ),
                                  child: Icon(Icons.verified_rounded, size: 36, color: primaryColor),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  strings.allTasksDoneTitle,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  strings.allTasksDoneSubtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                                  ),
                                ),
                                if (taskProv.inboxCount > 0) ...[
                                  const SizedBox(height: 18),
                                  TextButton.icon(
                                    onPressed: () => _showInboxSheet(context),
                                    icon: const Text('📥', style: TextStyle(fontSize: 14)),
                                    label: Text(
                                      '${strings.browseInbox} (${taskProv.inboxCount})',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor.withOpacity(isDark ? 0.15 : 0.08),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                      // === 情况 2：有未完成任务 -> 展现核心要务流 (支持拖拽调序) ===
                      if (pendingTasks.isNotEmpty) ...[
                        if (hasCapacitySplit)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                              child: Row(
                                children: [
                                  Text(
                                    '👑 ${strings.coreFocusTitle} (${corePendingTasks.length}/$dailyLimit)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // 核心未完成任务列表 (SliverReorderableList 真实顺位)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverReorderableList(
                            itemCount: corePendingTasks.length,
                            onReorder: (oldIndex, newIndex) {
                              taskProv.reorderIvyTasks(oldIndex, newIndex, corePendingTasks);
                            },
                            itemBuilder: (context, index) {
                              final task = corePendingTasks[index];
                              return ReorderableDelayedDragStartListener(
                                key: ValueKey(task.id),
                                index: index,
                                child: _buildDismissibleTaskCard(
                                  context,
                                  task,
                                  taskProv,
                                  isDark,
                                  primaryColor,
                                  strings,
                                ),
                              );
                            },
                          ),
                        ),

                        // 候补任务池区块 (超过每日容量的待办，支持折叠与心流提示)
                        if (hasCapacitySplit && bufferPendingTasks.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _bufferExpanded = !_bufferExpanded),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppTheme.darkBgSurface.withOpacity(0.6) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _bufferExpanded ? Icons.expand_more_rounded : Icons.chevron_right_rounded,
                                        size: 18,
                                        color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '📥 ${strings.bufferPoolTitle} (${strings.bufferCount(bufferPendingTasks.length)})',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppTheme.darkTextMain : const Color(0xFF334155),
                                              ),
                                            ),
                                            Text(
                                              strings.bufferTip,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (_bufferExpanded)
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              sliver: SliverReorderableList(
                                itemCount: bufferPendingTasks.length,
                                onReorder: (oldIndex, newIndex) {
                                  taskProv.reorderIvyTasks(oldIndex, newIndex, bufferPendingTasks);
                                },
                                itemBuilder: (context, index) {
                                  final task = bufferPendingTasks[index];
                                  return ReorderableDelayedDragStartListener(
                                    key: ValueKey(task.id),
                                    index: index,
                                    child: _buildDismissibleTaskCard(
                                      context,
                                      task,
                                      taskProv,
                                      isDark,
                                      primaryColor,
                                      strings,
                                      isBufferItem: true,
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ],

                      // === 优雅折叠收纳的已完成区块 (Logbook 哲学) ===
                      if (completedTasks.isNotEmpty && profileProv.completionBehavior != 'hide') ...[
                        SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => setState(() => _isCompletedExpanded = !_isCompletedExpanded),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 14, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${strings.completedSectionTitle} (${completedTasks.length})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isCompletedExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (_isCompletedExpanded)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final task = completedTasks[index];
                                  return _buildDismissibleTaskCard(
                                    context,
                                    task,
                                    taskProv,
                                    isDark,
                                    primaryColor,
                                    strings,
                                  );
                                },
                                childCount: completedTasks.length,
                              ),
                            ),
                          ),
                      ],

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 96),
                      ),
                    ],
                  ],
                ),

                // 5. 悬浮灵动输入胶囊 (Floating Pill Dock)
                _buildFloatingPillDock(context, isDark, primaryColor, strings),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Things 3 风格纯粹收集箱 (Inbox) 沉浸抽屉
  void _showInboxSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Consumer<TaskProvider>(
          builder: (context, taskProv, _) {
            final inboxTasks = taskProv.inboxTasks;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.82,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('📥', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.inboxTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              strings.inboxEmptyDesc,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${inboxTasks.length} 项',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 收集箱列表内容
                  if (inboxTasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_rounded,
                            size: 48,
                            color: (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)).withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            strings.inboxEmpty,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.darkTextMain : const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.inboxEmptyDesc,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: inboxTasks.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final task = inboxTasks[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  TaskDetailSheet.show(
                                    context,
                                    task: task,
                                    initialDate: _selectedDate,
                                    onNavigateTab: widget.onNavigateTab,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          taskProv.toggleTask(task.id);
                                        },
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              task.title,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            if (task.notes != null && task.notes!.isNotEmpty)
                                              Text(
                                                task.notes!,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // ☀️ 安排到今天
                                      InkWell(
                                        onTap: () async {
                                          HapticFeedback.mediumImpact();
                                          await taskProv.scheduleTaskToDate(task.id);
                                          if (sheetCtx.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('「${task.title}」已移至今日要务 ☀️'),
                                                duration: const Duration(milliseconds: 1500),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text('☀️', style: TextStyle(fontSize: 11)),
                                              const SizedBox(width: 4),
                                              Text(
                                                strings.moveToToday,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // 收集箱底部灵感输入条
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBgSurface : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: strings.inboxAddHint,
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                              ),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              filled: true,
                              fillColor: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (val) {
                              final trimmed = val.trim();
                              if (trimmed.isNotEmpty) {
                                taskProv.addTask(
                                  title: trimmed,
                                  dueDate: null, // 明确无日期，留在收集箱
                                );
                                textController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            final trimmed = textController.text.trim();
                            if (trimmed.isNotEmpty) {
                              taskProv.addTask(
                                title: trimmed,
                                dueDate: null, // 明确无日期，留在收集箱
                              );
                              textController.clear();
                            }
                          },
                          icon: Icon(Icons.arrow_upward_rounded, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Things 3 风格极简周历条 (通透无压迫，轻微底部细分割线)
  Widget _buildWeekStrip(
    TaskProvider taskProv,
    bool isDark,
    Color primaryColor,
    AppStrings strings,
    bool autoRollover,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final weekDaysList = strings.weekDays;

    return Container(
      color: isDark ? AppTheme.darkBgSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final date = startOfWeek.add(Duration(days: i));
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final hasTasks = taskProv.hasTasksOnDate(date, autoRollover: autoRollover);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDate = date);
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekDaysList[i],
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: primaryColor, width: 1.2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppTheme.darkTextMain : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // 任务小圆点
                  Container(
                    width: 3.5,
                    height: 3.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasTasks
                          ? (isSelected ? primaryColor : primaryColor.withOpacity(0.8))
                          : (isToday
                              ? (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1))
                              : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 清单分类横向滑动胶囊条 (Category Filter Strip)
  Widget _buildCategoryFilterStrip(
    TaskProvider taskProv,
    bool isDark,
    Color primaryColor,
    AppStrings strings,
  ) {
    final categories = taskProv.categories;
    final selectedId = taskProv.selectedCategoryId;

    return Container(
      color: isDark ? AppTheme.darkBgSurface : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // 1. 全部分类胶囊
            _buildCategoryPill(
              title: strings.categoryAll,
              isSelected: selectedId == null,
              color: primaryColor,
              count: taskProv.totalCount,
              isDark: isDark,
              onTap: () => taskProv.selectCategory(null),
            ),
            const SizedBox(width: 8),

            // 2. 各个具体清单分类
            ...categories.map((cat) {
              final isSelected = selectedId == cat.id;
              final count = taskProv.categoryTaskCounts[cat.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryPill(
                  title: cat.name,
                  isSelected: isSelected,
                  color: cat.uiColor,
                  count: count,
                  isDark: isDark,
                  onTap: () => taskProv.selectCategory(cat.id),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill({
    required String title,
    required bool isSelected,
    required Color color,
    required int count,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white.withOpacity(0.85)
                      : (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 滑动手势包装层 (Dismissible & Haptic Feedback)
  Widget _buildDismissibleTaskCard(
    BuildContext context,
    Task task,
    TaskProvider taskProv,
    bool isDark,
    Color primaryColor,
    AppStrings strings, {
    bool isBufferItem = false,
  }) {
    final isDone = task.isCompleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.horizontal,
        // 右滑底衬 (标记完成/撤回完成)
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDone
                  ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                  : [primaryColor, primaryColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isDone ? Icons.undo_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isDone ? strings.swipeToUncomplete : strings.swipeToComplete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        // 左滑底衬 (快速删除)
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                strings.swipeToDelete,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // 右滑：快捷完成/撤回
            HapticFeedback.lightImpact();
            final wasCompleted = task.isCompleted;
            await taskProv.toggleTask(task.id);
            if (!wasCompleted && context.mounted) {
              final pomoProv = context.read<PomodoroProvider>();
              final settled = await pomoProv.onTaskCompleted(task.id);
              if (settled > 0 && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 ${strings.taskCompletedAutoSettle} ($settled m)'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            }
            return false; // 保持卡片在列表中，仅状态变化
          } else {
            // 左滑：快捷删除，并弹出带 4 秒撤销 (Undo) 的悬浮提示
            HapticFeedback.mediumImpact();
            final subtasks = await taskProv.getSubtasks(task.id);
            await taskProv.deleteTask(task.id);
            if (context.mounted) {
              final pomoProv = context.read<PomodoroProvider>();
              pomoProv.onTaskDeleted(task.id);
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(strings.taskDeletedMsg(task.title)),
                  action: SnackBarAction(
                    label: strings.undo,
                    textColor: primaryColor,
                    onPressed: () async {
                      await taskProv.restoreTask(task, subtasks);
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return true;
          }
        },
        child: _buildPureTaskCard(
          context,
          task,
          taskProv,
          isDark,
          primaryColor,
          strings,
          isBufferItem: isBufferItem,
        ),
      ),
    );
  }

  /// Things 3 / Linear 雅致纯净任务卡片 (Pure Task Card)
  Widget _buildPureTaskCard(
    BuildContext context,
    Task task,
    TaskProvider taskProv,
    bool isDark,
    Color primaryColor,
    AppStrings strings, {
    bool isBufferItem = false,
  }) {
    final isDone = task.isCompleted;
    final subProg = taskProv.getSubtaskProgress(task.id);
    final pomoSummary = taskProv.getTaskPomoSummary(task.id);
    final pomoProv = context.watch<PomodoroProvider>();
    final isCurrentFocusing = pomoProv.isRunning && pomoProv.selectedTaskId == task.id;

    return Container(
      decoration: BoxDecoration(
        color: isDone
            ? (isDark ? AppTheme.darkBgPage : const Color(0xFFFAFAFA))
            : (isDark ? AppTheme.darkBgSurface : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentFocusing
              ? primaryColor
              : (isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9)),
          width: isCurrentFocusing ? 1.6 : 1.0,
        ),
        boxShadow: isDone
            ? []
            : (isCurrentFocusing
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(isDark ? 0.35 : 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF0F172A).withOpacity(0.03),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // 点击整卡展开任务属性抽屉
            TaskDetailSheet.show(
              context,
              task: task,
              initialDate: _selectedDate,
              onNavigateTab: widget.onNavigateTab,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 圆形极简 Checkbox (Things 3 经典)
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final wasCompleted = isDone;
                    await taskProv.toggleTask(task.id);
                    if (!wasCompleted && context.mounted) {
                      final pomoProv = context.read<PomodoroProvider>();
                      final settled = await pomoProv.onTaskCompleted(task.id);
                      if (settled > 0 && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎉 ${strings.taskCompletedAutoSettle} ($settled m)'),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isDone ? primaryColor : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                        width: 1.6,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),

                // 标题与元数据
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8))
                              : (isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A)),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Text(
                              '⏰ ${task.dueDate!.length >= 10 ? task.dueDate!.substring(5) : task.dueDate}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                            ),
                            Text(' · ',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8))),
                          ],
                          Builder(builder: (ctx) {
                            final cat = taskProv.getCategoryById(task.categoryId);
                            final catName = cat?.name ??
                                (task.categoryId == null ? strings.defaultCategoryName : 'List');
                            final catColor = cat?.uiColor ?? primaryColor;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: catColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    catName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: catColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                          // 子任务微进度胶囊
                          if (subProg != null && subProg.total > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: subProg.completed == subProg.total
                                    ? Colors.green.withOpacity(isDark ? 0.2 : 0.1)
                                    : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.checklist_rounded,
                                    size: 11,
                                    color: subProg.completed == subProg.total
                                        ? Colors.green
                                        : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    strings.subtaskProgress(subProg.completed, subProg.total),
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: subProg.completed == subProg.total
                                          ? Colors.green
                                          : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // 🍅 累计番茄专注徽标
                          if (pomoSummary != null && pomoSummary.count > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.amber.withOpacity(0.15) : Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? Colors.amber.withOpacity(0.3) : Colors.amber.withOpacity(0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🍅', style: TextStyle(fontSize: 9.5)),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    '${pomoSummary.count}',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.amber[300] : Colors.amber[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (task.notes != null && task.notes!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('📝', style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 右侧操作簇: 快捷直达 🍅 专注 / 专注中呼吸药丸 + 艾利序号
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDone) ...[
                      if (isCurrentFocusing)
                        GestureDetector(
                          onTap: () {
                            widget.onNavigateTab?.call(1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${strings.focusingNow} ${pomoProv.formattedTime}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: () => _handleStartFocusOnTask(context, task, strings),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: primaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🍅', style: TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                Text(
                                  strings.focusAction,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],

                    // 艾利法序号：未完成且非候补时使用微高亮，体现艾利法则
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: !isDone && !isBufferItem
                            ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
                            : (isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${task.ivyOrder}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: !isDone && !isBufferItem
                              ? primaryColor
                              : (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 悬浮灵动输入胶囊 (Floating Pill Dock · Linear / Things 风格)
  Widget _buildFloatingPillDock(BuildContext context, bool isDark, Color primaryColor, AppStrings strings) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 5, 6, 5),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.darkBgSurface.withOpacity(0.96)
              : Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: isDark
                  ? AppTheme.darkBorder
                  : const Color(0xFFE2E8F0).withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.35)
                  : const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _quickTitleController,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: strings.quickAddHint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _quickAddSubmit(context),
              ),
            ),
            const SizedBox(width: 8),
            // 右侧彩色圆圈 + 号按钮，展开完整属性抽屉
            GestureDetector(
              onTap: () {
                TaskDetailSheet.show(
                  context,
                  initialDate: _selectedDate,
                  onNavigateTab: widget.onNavigateTab,
                );
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStartFocusOnTask(
    BuildContext context,
    Task task,
    AppStrings strings,
  ) async {
    final pomoProv = context.read<PomodoroProvider>();
    if (pomoProv.isRunning &&
        pomoProv.selectedTaskId != null &&
        pomoProv.selectedTaskId != task.id) {
      final currentTitle = pomoProv.selectedTaskTitle ?? strings.freeFocus;
      final elapsedMins = (pomoProv.targetMinutes * 60 - pomoProv.remainingSeconds) ~/ 60;

      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.focusConflictTitle),
          content: Text(strings.focusConflictDesc(currentTitle, elapsedMins)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: Text(strings.continueCurrentFocus),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              child: Text(strings.discardAndSwitch, style: const TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'settle'),
              child: Text(strings.settleAndSwitch),
            ),
          ],
        ),
      );

      if (action == 'cancel' || action == null) return;

      await pomoProv.switchTaskAndRestart(
        task.id,
        task.title,
        saveCurrent: action == 'settle',
      );
    } else {
      pomoProv.selectTask(task.id, task.title);
      pomoProv.start();
    }

    widget.onNavigateTab?.call(1);
  }
}
