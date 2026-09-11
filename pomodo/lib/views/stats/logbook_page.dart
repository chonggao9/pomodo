import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';

class LogbookPage extends StatefulWidget {
  const LogbookPage({super.key});

  @override
  State<LogbookPage> createState() => _LogbookPageState();
}

class _LogbookPageState extends State<LogbookPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCompletedTime(DateTime dt, bool isToday, bool isYesterday) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    if (isToday) return '$hour:$minute';
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks, AppStrings strings) {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterdayStr =
        '${yesterdayDate.year}-${yesterdayDate.month.toString().padLeft(2, '0')}-${yesterdayDate.day.toString().padLeft(2, '0')}';

    final grouped = <String, List<Task>>{};

    for (final task in tasks) {
      final dateStr = task.completedAt ?? task.updatedAt;
      final parsed = DateTime.tryParse(dateStr);
      String groupKey;

      if (parsed == null) {
        groupKey = strings.earlier;
      } else {
        final dayStr =
            '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        if (dayStr == todayStr) {
          groupKey = strings.today;
        } else if (dayStr == yesterdayStr) {
          groupKey = strings.yesterday;
        } else if (now.difference(parsed).inDays < 7) {
          groupKey = strings.earlierThisWeek;
        } else {
          groupKey = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}';
        }
      }

      grouped.putIfAbsent(groupKey, () => []).add(task);
    }

    return grouped;
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
      appBar: AppBar(
        backgroundColor: bgPage,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.logbookTitle,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textMain),
            ),
            Consumer<TaskProvider>(
              builder: (context, taskProv, _) {
                final count = taskProv.allCompletedTasks.length;
                return Text(
                  '$count ${strings.items} ${strings.allTimeCompleted}',
                  style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProv, _) {
          final allCompleted = taskProv.allCompletedTasks;

          // 搜索过滤
          final filtered = _searchQuery.trim().isEmpty
              ? allCompleted
              : allCompleted.where((t) {
                  final titleMatch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
                  final notesMatch = t.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                  return titleMatch || notesMatch;
                }).toList();

          final grouped = _groupTasksByDate(filtered, strings);

          return Column(
            children: [
              // 搜索框
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(fontSize: 14, color: textMain),
                    decoration: InputDecoration(
                      hintText: strings.searchCompletedTasks,
                      hintStyle: TextStyle(fontSize: 13, color: textMuted),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: textMuted),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 18, color: textMuted),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // 列表内容
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.archive_outlined,
                                size: 56,
                                color: textMuted.withOpacity(0.4),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                strings.noCompletedTasks,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: textMain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                strings.noCompletedTasksDesc,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final groupKey = grouped.keys.elementAt(groupIndex);
                          final groupTasks = grouped[groupKey]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 分组吸顶标题
                              Padding(
                                padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      groupKey,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: textSub,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${groupTasks.length})',
                                      style: TextStyle(fontSize: 11, color: textMuted),
                                    ),
                                  ],
                                ),
                              ),

                              // 该组下的任务卡片
                              ...groupTasks.map((task) {
                                final parsedTime = DateTime.tryParse(task.completedAt ?? task.updatedAt);
                                final isToday = groupKey == strings.today;
                                final isYesterday = groupKey == strings.yesterday;
                                final timeFormatted = parsedTime != null
                                    ? _formatCompletedTime(parsedTime, isToday, isYesterday)
                                    : '';

                                final pomoStat = taskProv.getTaskPomoSummary(task.id);
                                final category = task.categoryId != null
                                    ? taskProv.categories.cast<dynamic>().firstWhere(
                                          (c) => c.id == task.categoryId,
                                          orElse: () => null,
                                        )
                                    : null;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: cardBorder),
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    leading: InkWell(
                                      onTap: () async {
                                        HapticFeedback.lightImpact();
                                        await taskProv.reopenTask(task.id);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(strings.taskReopenedMsg),
                                              duration: const Duration(seconds: 2),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: primaryColor, width: 1.5),
                                        ),
                                        child: Icon(Icons.check_rounded, size: 18, color: primaryColor),
                                      ),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textSub,
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: textMuted,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          // 完成时间
                                          if (timeFormatted.isNotEmpty) ...[
                                            Text(
                                              timeFormatted,
                                              style: TextStyle(fontSize: 11, color: textMuted),
                                            ),
                                            const SizedBox(width: 8),
                                          ],

                                          // 分类胶囊
                                          if (category != null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                category.name,
                                                style: TextStyle(fontSize: 10, color: textSub),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],

                                          // 番茄沉淀
                                          if (pomoStat != null && pomoStat.count > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.redAccent.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '🍅 ${pomoStat.count}',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(Icons.more_horiz_rounded, size: 20, color: textMuted),
                                      color: cardBg,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: cardBorder),
                                      ),
                                      onSelected: (val) async {
                                        if (val == 'reopen') {
                                          HapticFeedback.lightImpact();
                                          await taskProv.reopenTask(task.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(strings.taskReopenedMsg),
                                                duration: const Duration(seconds: 2),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'reopen',
                                          child: Row(
                                            children: [
                                              Icon(Icons.undo_rounded, size: 16, color: primaryColor),
                                              const SizedBox(width: 8),
                                              Text(
                                                strings.reopenTask,
                                                style: TextStyle(fontSize: 13, color: textMain),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
