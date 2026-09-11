import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/pomodoro_provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/pomodoro_dial.dart';

class PomodoroPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const PomodoroPage({super.key, this.onNavigateTab});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  bool _isShowingCompletionSheet = false;

  void _checkAndShowCompletionSheet(
    BuildContext context,
    PomodoroProvider pomo,
    AppStrings strings,
  ) {
    if (pomo.showCompletionPrompt && !_isShowingCompletionSheet) {
      _isShowingCompletionSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showCompletionSheet(context, pomo, strings);
      });
    }
  }

  void _showCompletionSheet(
    BuildContext context,
    PomodoroProvider pomo,
    AppStrings strings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final taskId = pomo.selectedTaskId;
    final taskTitle = pomo.selectedTaskTitle;

    HapticFeedback.heavyImpact();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                strings.focusCompletedDialogTitle,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                taskTitle != null
                    ? '已完成针对「$taskTitle」的 ${pomo.targetMinutes} 分钟专注！'
                    : '已完成 ${pomo.targetMinutes} 分钟的深度自由专注！',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              // 核心动作 1: 达成目标，划线完成
              if (taskId != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      pomo.dismissCompletionPrompt();
                      _isShowingCompletionSheet = false;
                      final taskProv = context.read<TaskProvider>();
                      await taskProv.toggleTask(taskId);
                      await taskProv.refreshPomoSummary();
                      pomo.unbindTask();
                      widget.onNavigateTab?.call(0);
                    },
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      strings.markTaskCompletedAction,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // 核心动作 2 & 3: 进入 5m 短休 或 再来一个番茄
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        pomo.dismissCompletionPrompt();
                        _isShowingCompletionSheet = false;
                        pomo.startRest(5);
                      },
                      icon: const Text('☕', style: TextStyle(fontSize: 15)),
                      label: Text(
                        strings.takeBreakAction,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor.withOpacity(0.35)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: primaryColor.withOpacity(isDark ? 0.12 : 0.06),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        pomo.dismissCompletionPrompt();
                        _isShowingCompletionSheet = false;
                        pomo.start();
                      },
                      icon: const Text('🔁', style: TextStyle(fontSize: 15)),
                      label: Text(
                        strings.continueFocusAction,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextMain : const Color(0xFF334155),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ).then((_) {
      _isShowingCompletionSheet = false;
    });
  }

  void _showTaskPickerSheet(
    BuildContext context,
    PomodoroProvider pomo,
    AppStrings strings,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final taskProv = context.read<TaskProvider>();
    final pendingTasks =
        taskProv.tasksForDate(DateTime.now()).where((t) => !t.isCompleted).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.65,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkBgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      strings.selectTaskSheetTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pendingTasks.length} 项可用',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (pendingTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      '今日暂无待办任务',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: pendingTasks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final t = pendingTasks[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                          ),
                        ),
                        tileColor: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                        leading: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withOpacity(0.12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${t.ivyOrder}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                          ),
                        ),
                        trailing: Icon(Icons.play_circle_outline_rounded, color: primaryColor),
                        onTap: () {
                          pomo.selectTask(t.id, t.title);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleEarlyComplete(
    BuildContext context,
    PomodoroProvider pomo,
    AppStrings strings,
  ) async {
    final taskId = pomo.selectedTaskId;
    final taskTitle = pomo.selectedTaskTitle ?? strings.freeFocus;
    final actualMinutes = await pomo.completeEarly();

    if (taskId != null && context.mounted) {
      // 在待办清单中就地划线归档
      final taskProv = context.read<TaskProvider>();
      await taskProv.toggleTask(taskId);
      await taskProv.refreshPomoSummary();
    }

    if (context.mounted) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('🎉', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${strings.focusAccomplished} ($actualMinutes m)! 「$taskTitle」${strings.taskArchived}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 2200),
        ),
      );

      // 700ms 自动平滑切回今日待办页 Tab 0
      Future.delayed(const Duration(milliseconds: 700), () {
        widget.onNavigateTab?.call(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final bgPage = isDark ? AppTheme.darkBgPage : AppTheme.bgPage;
    final textMain = isDark ? AppTheme.darkTextMain : AppTheme.textPrimary;
    final textSub = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return Scaffold(
      backgroundColor: bgPage,
      body: SafeArea(
        child: Consumer<PomodoroProvider>(
          builder: (context, pomo, child) {
            _checkAndShowCompletionSheet(context, pomo, strings);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 顶部标题 (支持深度专注 / 轻松短休)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pomo.isRestMode
                                ? strings.restModeTitle.toUpperCase()
                                : strings.deepFocus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pomo.isRestMode ? strings.restModeTitle : strings.deepFocus,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: textMain,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: pomo.isRunning
                              ? primaryColor.withOpacity(0.12)
                              : (pomo.isPaused
                                  ? Colors.amber.withOpacity(0.15)
                                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04))),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: pomo.isRunning
                                    ? primaryColor
                                    : (pomo.isPaused
                                        ? Colors.amber[700]
                                        : (isDark ? Colors.white38 : Colors.black26)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pomo.isRestMode
                                  ? (pomo.isRunning ? '短休中' : (pomo.isPaused ? '休息暂停' : '准备短休'))
                                  : (pomo.isRunning
                                      ? strings.focusing
                                      : (pomo.isPaused ? strings.paused : strings.ready)),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: pomo.isRunning
                                    ? primaryColor
                                    : (pomo.isPaused
                                        ? (isDark ? Colors.amber[300] : Colors.amber[800])
                                        : textSub),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 2. 关联的任务胶囊 (已选任务 / 快捷挑选任务 / 休息提示)
                  Builder(builder: (context) {
                    final taskProv = context.watch<TaskProvider>();
                    final activeTask = pomo.selectedTaskId != null
                        ? taskProv.tasks.cast<Task?>().firstWhere(
                              (t) => t?.id == pomo.selectedTaskId,
                              orElse: () => null,
                            )
                        : null;
                    final displayTitle = activeTask?.title ?? pomo.selectedTaskTitle;

                    if (displayTitle != null) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.radio_button_checked, size: 15, color: primaryColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => pomo.unbindTask(),
                              child: Icon(Icons.close, size: 15, color: primaryColor),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  if (pomo.selectedTaskId == null && pomo.selectedTaskTitle == null && !pomo.isRunning && !pomo.isRestMode)
                    GestureDetector(
                      onTap: () => _showTaskPickerSheet(context, pomo, strings),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withOpacity(0.28)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 13)),
                            const SizedBox(width: 6),
                            Text(
                              strings.selectTaskToFocus,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: primaryColor),
                          ],
                        ),
                      ),
                    ),

                  // 3. 博朗拟物 60 刻度精密机械表盘
                  PomodoroDial(
                    progress: pomo.progress,
                    formattedTime: pomo.formattedTime,
                    isRunning: pomo.isRunning,
                    onTap: () {
                      if (pomo.isRunning) {
                        pomo.pause();
                      } else {
                        pomo.start();
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // 4. 预设时长选择 (15 / 25 / 35 / 45m，短休模式下隐藏)
                  if (!pomo.isRestMode) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: pomo.presetMinutes.map((m) {
                        final isSelected = pomo.targetMinutes == m;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text('${m}m'),
                            selected: isSelected,
                            selectedColor: primaryColor,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : textSub,
                            ),
                            backgroundColor: isDark ? AppTheme.darkBgSurface : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: pomo.isRunning
                                ? null
                                : (selected) {
                                    if (selected) pomo.setTargetMinutes(m);
                                  },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkBgSurface : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.restModeDesc,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 5. 核心控制按钮栏
                  _buildActionsRow(context, pomo, strings, primaryColor, isDark),

                  const SizedBox(height: 32),

                  // 6. 离线白噪音声学微仓 (pomo-ambient-dock)
                  _buildAmbientDock(pomo, strings, primaryColor, isDark),

                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 专注三态控制栏 (空闲单大键 / 运行态双键 / 暂停态三键 / 短休模式)
  Widget _buildActionsRow(
    BuildContext context,
    PomodoroProvider pomo,
    AppStrings strings,
    Color primaryColor,
    bool isDark,
  ) {
    // 态 0: 轻松短休模式 (暂停/继续 + 结束短休)
    if (pomo.isRestMode) {
      return Row(
        children: [
          Expanded(
            flex: 12,
            child: ElevatedButton.icon(
              onPressed: () => pomo.isRunning ? pomo.pause() : pomo.resume(),
              icon: Icon(pomo.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 20),
              label: Text(
                pomo.isRunning ? '暂停短休' : '继续短休',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 10,
            child: OutlinedButton.icon(
              onPressed: () => pomo.reset(),
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text(
                '结束短休',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );
    }

    // 态 A: 正在运行中 (暂停专注 + 提前完成并划线)
    if (pomo.isRunning) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => pomo.pause(),
              icon: const Icon(Icons.pause_rounded, size: 20),
              label: Text(
                strings.pauseFocus,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _handleEarlyComplete(context, pomo, strings),
              icon: Icon(Icons.check_circle_outline_rounded, size: 18, color: primaryColor),
              label: Text(
                strings.earlyComplete,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark
                    ? primaryColor.withOpacity(0.15)
                    : const Color(0xFFE8F5F4),
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );
    }

    // 态 B: 已暂停 (继续专注 + 达成划线 + 放弃重置)
    if (pomo.isPaused) {
      return Row(
        children: [
          Expanded(
            flex: 12,
            child: ElevatedButton.icon(
              onPressed: () => pomo.resume(),
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(
                strings.resumeFocus,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: ElevatedButton.icon(
              onPressed: () => _handleEarlyComplete(context, pomo, strings),
              icon: Icon(Icons.check_rounded, size: 16, color: primaryColor),
              label: Text(
                strings.completeTask,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? primaryColor.withOpacity(0.15)
                    : const Color(0xFFE8F5F4),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: primaryColor.withOpacity(0.3)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: OutlinedButton(
              onPressed: () => pomo.reset(),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.darkBgSurface
                    : const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                strings.abandonReset,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // 态 C: 空闲准备态 (单个沉浸大按钮)
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => pomo.start(),
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: Text(
          '${strings.startFocus} (${pomo.targetMinutes}m)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
      ),
    );
  }

  /// 自然采样声景微仓 (pomo-ambient-dock)
  Widget _buildAmbientDock(
    PomodoroProvider pomo,
    AppStrings strings,
    Color primaryColor,
    bool isDark,
  ) {
    final ambientOptions = [
      {'name': strings.rain, 'icon': '🌧️', 'key': '🌧️ 窗台夜雨'},
      {'name': strings.ocean, 'icon': '🌊', 'key': '🌊 深海潮汐'},
      {'name': strings.campfire, 'icon': '🌲', 'key': '🌲 夜色篝火'},
      {'name': strings.mute, 'icon': '🔇', 'key': '🔇 静音模式'},
    ];

    final cardBg = isDark ? AppTheme.darkBgSurface : Colors.white;
    final cardBorder = isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9);
    final cardTitleColor = isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cardBorder),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 6),
                  Text(
                    strings.soundScapes,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cardTitleColor,
                    ),
                  ),
                ],
              ),
              if (!pomo.selectedSound.contains('静音'))
                GestureDetector(
                  onTap: () => pomo.toggleSoundPreview(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (pomo.isRunning || pomo.isPreviewPlaying)
                          ? primaryColor.withOpacity(0.15)
                          : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (pomo.isRunning || pomo.isPreviewPlaying)
                              ? Icons.volume_up_rounded
                              : Icons.volume_mute_rounded,
                          size: 13,
                          color: (pomo.isRunning || pomo.isPreviewPlaying)
                              ? primaryColor
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pomo.isRunning
                              ? strings.playing
                              : (pomo.isPreviewPlaying ? strings.auditioning : strings.audition),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (pomo.isRunning || pomo.isPreviewPlaying)
                                ? primaryColor
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 颗环境声微药丸 (横向弹性排列)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ambientOptions.map((opt) {
                final isSelected = pomo.selectedSound == opt['key'];
                final isPlayingThis = isSelected && (pomo.isRunning || pomo.isPreviewPlaying);

                final optBg = isSelected
                    ? (isDark ? primaryColor.withOpacity(0.2) : const Color(0xFFE8F5F4))
                    : (isDark ? AppTheme.darkBgCard : const Color(0xFFF8FAFC));
                final optBorder = isSelected
                    ? primaryColor
                    : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0));
                final optTextColor = isSelected
                    ? primaryColor
                    : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569));

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      pomo.setSelectedSound(opt['key']!);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 76,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: optBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: optBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlayingThis && !opt['key']!.contains('静音')) ...[
                            _SoundWaveBars(primaryColor: primaryColor),
                            const SizedBox(height: 4),
                          ] else ...[
                            Text(opt['icon']!, style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            opt['name']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: optTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 正在播放时微动效声波条
class _SoundWaveBars extends StatefulWidget {
  final Color primaryColor;

  const _SoundWaveBars({required this.primaryColor});

  @override
  State<_SoundWaveBars> createState() => _SoundWaveBarsState();
}

class _SoundWaveBarsState extends State<_SoundWaveBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final val = _anim.value;
        return SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 2.5,
                height: 6 + 6 * val,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 2.5,
                height: 12 - 6 * val,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 2.5,
                height: 7 + 5 * val,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
