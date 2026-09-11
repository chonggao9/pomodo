import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';
import '../../models/pomodoro_session.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import 'logbook_page.dart';

enum StatsTimeRange { today, week }

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  StatsTimeRange _timeRange = StatsTimeRange.today;
  List<PomodoroSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadStatsData();
  }

  Future<void> _loadStatsData() async {
    final sessions = await DatabaseHelper.instance.getAllSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final bgPage = isDark ? AppTheme.darkBgPage : AppTheme.bgPage;
    final cardBg = isDark ? AppTheme.darkBgSurface : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : AppTheme.borderLight;
    final textMain = isDark ? AppTheme.darkTextMain : AppTheme.textPrimary;
    final textSub = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textMuted = isDark ? AppTheme.darkTextMuted : AppTheme.textMuted;

    return Scaffold(
      backgroundColor: bgPage,
      body: SafeArea(
        child: RefreshIndicator(
          color: primaryColor,
          onRefresh: () async {
            await context.read<TaskProvider>().loadTasks();
            await _loadStatsData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Consumer<TaskProvider>(
              builder: (context, taskProv, _) {
                final now = DateTime.now();
                final todayStr =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                // 本周计算 (周一 00:00:00 至 周日 23:59:59)
                final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
                final sunday = DateTime(monday.year, monday.month, monday.day + 6, 23, 59, 59);

                // 筛选当前时间范围内的 Sessions
                final periodSessions = _sessions.where((s) {
                  if (_timeRange == StatsTimeRange.today) {
                    return s.startedAt.startsWith(todayStr);
                  } else {
                    final dt = DateTime.tryParse(s.startedAt);
                    if (dt == null) return false;
                    return !dt.isBefore(monday) && !dt.isAfter(sunday);
                  }
                }).toList();

                final focusMinutes = periodSessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
                final focusGoalMinutes = _timeRange == StatsTimeRange.today ? 60 : 420; // 60m 或 7h
                final focusRate = focusGoalMinutes == 0
                    ? 0.0
                    : (focusMinutes / focusGoalMinutes).clamp(0.0, 1.0);

                // 任务完成率计算
                int completedTasksCount = 0;
                int totalTasksCount = 0;
                double taskRate = 0.0;

                if (_timeRange == StatsTimeRange.today) {
                  final todayTasks = taskProv.tasksForDate(now);
                  totalTasksCount = todayTasks.length;
                  completedTasksCount = todayTasks.where((t) => t.isCompleted).length;
                  taskRate = totalTasksCount == 0 ? 0.0 : (completedTasksCount / totalTasksCount);
                } else {
                  final allTasks = taskProv.tasks;
                  final weekTasks = allTasks.where((t) {
                    final completedDt = DateTime.tryParse(t.completedAt ?? '');
                    if (completedDt != null && !completedDt.isBefore(monday) && !completedDt.isAfter(sunday)) {
                      return true;
                    }
                    if (t.dueDate != null) {
                      final dueDt = DateTime.tryParse(t.dueDate!);
                      if (dueDt != null && !dueDt.isBefore(monday) && !dueDt.isAfter(sunday)) {
                        return true;
                      }
                    }
                    return false;
                  }).toList();

                  totalTasksCount = weekTasks.length;
                  completedTasksCount = weekTasks.where((t) => t.isCompleted).length;
                  taskRate = totalTasksCount == 0 ? 0.0 : (completedTasksCount / totalTasksCount);
                }

                taskRate = taskRate.clamp(0.0, 1.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 顶栏：标题 + 归档入口胶囊
                    _buildHeader(
                      context,
                      taskProv,
                      strings,
                      primaryColor,
                      textMain,
                      cardBg,
                      cardBorder,
                      isDark,
                    ),

                    const SizedBox(height: 16),

                    // 2. 维度切换胶囊 (今日 / 本周)
                    _buildTimeRangeSelector(primaryColor, cardBg, cardBorder, textSub, strings),

                    const SizedBox(height: 16),

                    // 3. Apple 风格双环闭环 Hero 卡片
                    _buildDualRingsCard(
                      taskRate: taskRate,
                      focusRate: focusRate,
                      focusMinutes: focusMinutes,
                      focusGoalMinutes: focusGoalMinutes,
                      completedTasksCount: completedTasksCount,
                      totalTasksCount: totalTasksCount,
                      primaryColor: primaryColor,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textMain: textMain,
                      textSub: textSub,
                      textMuted: textMuted,
                      strings: strings,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // 4. Things 3 历史达成归档室 (Logbook) 入口卡片
                    _buildLogbookEntryCard(
                      context,
                      taskProv,
                      primaryColor,
                      cardBg,
                      cardBorder,
                      textMain,
                      textSub,
                      textMuted,
                      strings,
                      isDark,
                    ),

                    const SizedBox(height: 20),

                    // 5. 分类时间投资分布 (时间究竟花在哪)
                    _buildCategoryDistributionCard(
                      periodSessions: periodSessions,
                      totalMinutes: focusMinutes,
                      taskProv: taskProv,
                      primaryColor: primaryColor,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textMain: textMain,
                      textSub: textSub,
                      textMuted: textMuted,
                      strings: strings,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 20),

                    // 6. 专注心流流水记录 (按时段纯净列表)
                    _buildFocusRecordsSection(
                      periodSessions: periodSessions,
                      taskProv: taskProv,
                      primaryColor: primaryColor,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      textMain: textMain,
                      textSub: textSub,
                      textMuted: textMuted,
                      strings: strings,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. 顶栏 ---
  Widget _buildHeader(
    BuildContext context,
    TaskProvider taskProv,
    AppStrings strings,
    Color primaryColor,
    Color textMain,
    Color cardBg,
    Color cardBorder,
    bool isDark,
  ) {
    final allCompletedCount = taskProv.allCompletedTasks.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERFORMANCE & REVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              strings.statsReview,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: textMain,
              ),
            ),
          ],
        ),

        // 右上角 Logbook 药丸入口
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogbookPage()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.archive_outlined, size: 16, color: primaryColor),
                const SizedBox(width: 6),
                Text(
                  strings.logbookTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                if (allCompletedCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$allCompletedCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. 维度切换胶囊 ---
  Widget _buildTimeRangeSelector(
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textSub,
    AppStrings strings,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeRangeItem(
              title: strings.dimensionToday,
              isSelected: _timeRange == StatsTimeRange.today,
              primaryColor: primaryColor,
              textSub: textSub,
              onTap: () => setState(() => _timeRange = StatsTimeRange.today),
            ),
          ),
          Expanded(
            child: _buildTimeRangeItem(
              title: strings.dimensionWeek,
              isSelected: _timeRange == StatsTimeRange.week,
              primaryColor: primaryColor,
              textSub: textSub,
              onTap: () => setState(() => _timeRange = StatsTimeRange.week),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeItem({
    required String title,
    required bool isSelected,
    required Color primaryColor,
    required Color textSub,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textSub,
          ),
        ),
      ),
    );
  }

  // --- 3. Apple 风格双环闭环 Hero 卡片 ---
  Widget _buildDualRingsCard({
    required double taskRate,
    required double focusRate,
    required int focusMinutes,
    required int focusGoalMinutes,
    required int completedTasksCount,
    required int totalTasksCount,
    required Color primaryColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textMain,
    required Color textSub,
    required Color textMuted,
    required AppStrings strings,
    required bool isDark,
  }) {
    const focusColor = Color(0xFFF59E0B); // 琥珀金/专注橙

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          // 左侧：双环绘制 Canvas
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _AppleDualRingsPainter(
                taskProgress: taskRate,
                focusProgress: focusRate,
                taskColor: primaryColor,
                focusColor: focusColor,
                strokeWidth: 10,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timeRange == StatsTimeRange.today
                          ? '${focusMinutes}m'
                          : '${(focusMinutes / 60).toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: textMain,
                      ),
                    ),
                    Text(
                      _timeRange == StatsTimeRange.today ? strings.tabFocus : strings.dimensionWeek,
                      style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 24),

          // 右侧：双指标图例与数值说明
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 外环：任务达成率
                _buildRingLegendRow(
                  color: primaryColor,
                  label: strings.ringTaskRate,
                  value: '${(taskRate * 100).toInt()}%',
                  detail: '$completedTasksCount / $totalTasksCount ${strings.items}',
                  textMain: textMain,
                  textSub: textSub,
                ),

                const SizedBox(height: 16),

                // 内环：专注目标完成率
                _buildRingLegendRow(
                  color: focusColor,
                  label: strings.ringFocusRate,
                  value: '${(focusRate * 100).toInt()}%',
                  detail: '$focusMinutes / ${focusGoalMinutes}m',
                  textMain: textMain,
                  textSub: textSub,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingLegendRow({
    required Color color,
    required String label,
    required String value,
    required String detail,
    required Color textMain,
    required Color textSub,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain)),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text(detail, style: TextStyle(fontSize: 11, color: textSub.withOpacity(0.7))),
        ),
      ],
    );
  }

  // --- 4. Things 3 历史达成归档卡片 (Logbook Entry) ---
  Widget _buildLogbookEntryCard(
    BuildContext context,
    TaskProvider taskProv,
    Color primaryColor,
    Color cardBg,
    Color cardBorder,
    Color textMain,
    Color textSub,
    Color textMuted,
    AppStrings strings,
    bool isDark,
  ) {
    final count = taskProv.allCompletedTasks.length;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LogbookPage()),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.emoji_events_rounded, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.logbookTitle,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    strings.logbookSubtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count ${strings.items}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textSub),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. 分类时间投资分布卡片 ---
  Widget _buildCategoryDistributionCard({
    required List<PomodoroSession> periodSessions,
    required int totalMinutes,
    required TaskProvider taskProv,
    required Color primaryColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textMain,
    required Color textSub,
    required Color textMuted,
    required AppStrings strings,
    required bool isDark,
  }) {
    if (totalMinutes == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  strings.categoryTimeDist,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Icon(Icons.hourglass_empty_rounded, size: 36, color: textMuted.withOpacity(0.4)),
            const SizedBox(height: 8),
            Text(strings.noCategoryTimeData, style: TextStyle(fontSize: 12, color: textMuted)),
          ],
        ),
      );
    }

    // 按分类聚合分钟数
    final Map<String, int> catMinutes = {};
    final tasksMap = {for (var t in taskProv.tasks) t.id: t};

    for (final s in periodSessions) {
      String catKey = 'free';
      if (s.taskId != null) {
        final task = tasksMap[s.taskId];
        if (task?.categoryId != null) {
          catKey = task!.categoryId!;
        } else {
          catKey = 'uncategorized';
        }
      }
      catMinutes[catKey] = (catMinutes[catKey] ?? 0) + s.durationMinutes;
    }

    final catMap = {for (var c in taskProv.categories) c.id: c};

    // 转换为列表并按分钟数倒序
    final sortedEntries = catMinutes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    strings.categoryTimeDist,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textMain),
                  ),
                ],
              ),
              Text(
                '$totalMinutes ${strings.minutesTotal}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primaryColor),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 多段式横向彩色比例条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: sortedEntries.map((e) {
                  final ratio = (e.value / totalMinutes).clamp(0.0, 1.0);
                  Color segmentColor = primaryColor;
                  if (e.key == 'free') {
                    segmentColor = const Color(0xFF64748B);
                  } else if (e.key == 'uncategorized') {
                    segmentColor = const Color(0xFF94A3B8);
                  } else {
                    final cat = catMap[e.key];
                    if (cat != null) {
                      segmentColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
                    }
                  }

                  return Expanded(
                    flex: (ratio * 1000).toInt().clamp(1, 1000),
                    child: Container(color: segmentColor),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 分类条目明细
          ...sortedEntries.map((e) {
            String name = strings.freeFocus;
            Color dotColor = const Color(0xFF64748B);

            if (e.key == 'uncategorized') {
              name = strings.uncategorized;
              dotColor = const Color(0xFF94A3B8);
            } else if (e.key != 'free') {
              final cat = catMap[e.key];
              if (cat != null) {
                name = cat.name;
                dotColor = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
              }
            }

            final pct = ((e.value / totalMinutes) * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSub),
                    ),
                  ),
                  Text(
                    '${e.value}m',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textMain),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$pct%',
                      textAlign: TextAlign.end,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // --- 6. 专注心流流水明细 ---
  Widget _buildFocusRecordsSection({
    required List<PomodoroSession> periodSessions,
    required TaskProvider taskProv,
    required Color primaryColor,
    required Color cardBg,
    required Color cardBorder,
    required Color textMain,
    required Color textSub,
    required Color textMuted,
    required AppStrings strings,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              strings.highValueSessions,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textMain),
            ),
            Text(
              '${periodSessions.length} ${strings.validCycles}',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (periodSessions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder),
            ),
            child: Center(
              child: Text(strings.noSessions, style: TextStyle(fontSize: 13, color: textMuted)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: periodSessions.take(8).length,
            itemBuilder: (context, index) {
              final s = periodSessions[index];
              final timeStr = s.startedAt.length >= 16
                  ? s.startedAt.substring(5, 16).replaceAll('T', ' ')
                  : s.startedAt;

              final title = s.notes?.isNotEmpty == true
                  ? s.notes!
                  : (s.taskId != null
                      ? (taskProv.tasks.cast<Task?>().firstWhere(
                                (t) => t?.id == s.taskId,
                                orElse: () => null,
                              )?.title ??
                          strings.focusSession)
                      : strings.freeFocus);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.bolt_rounded, size: 18, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMain),
                          ),
                          const SizedBox(height: 2),
                          Text(timeStr, style: TextStyle(fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${s.durationMinutes}m',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

// --- Apple 双环 Canvas 绘制器 (防除零与防越界保护) ---
class _AppleDualRingsPainter extends CustomPainter {
  final double taskProgress;
  final double focusProgress;
  final Color taskColor;
  final Color focusColor;
  final double strokeWidth;

  _AppleDualRingsPainter({
    required this.taskProgress,
    required this.focusProgress,
    required this.taskColor,
    required this.focusColor,
    this.strokeWidth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - strokeWidth / 2;
    final innerRadius = outerRadius - strokeWidth - 5;

    if (outerRadius <= 0 || innerRadius <= 0) return;

    const startAngle = -pi / 2;

    // 1. 外环 (任务达成率)
    final outerBgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = taskColor.withOpacity(0.12);
    canvas.drawCircle(center, outerRadius, outerBgPaint);

    final safeTaskRate = taskProgress.isFinite ? taskProgress.clamp(0.0, 1.0) : 0.0;
    if (safeTaskRate > 0) {
      final outerSweep = safeTaskRate * 2 * pi;
      final outerFgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = taskColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        outerSweep,
        false,
        outerFgPaint,
      );
    }

    // 2. 内环 (专注达成率)
    final innerBgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = focusColor.withOpacity(0.15);
    canvas.drawCircle(center, innerRadius, innerBgPaint);

    final safeFocusRate = focusProgress.isFinite ? focusProgress.clamp(0.0, 1.0) : 0.0;
    if (safeFocusRate > 0) {
      final innerSweep = safeFocusRate * 2 * pi;
      final innerFgPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..color = focusColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        innerSweep,
        false,
        innerFgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AppleDualRingsPainter oldDelegate) {
    return oldDelegate.taskProgress != taskProgress ||
        oldDelegate.focusProgress != focusProgress ||
        oldDelegate.taskColor != taskColor ||
        oldDelegate.focusColor != focusColor;
  }
}
