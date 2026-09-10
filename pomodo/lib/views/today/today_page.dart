import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';

class TodayPage extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const TodayPage({super.key, this.onNavigateTab});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final TextEditingController _quickTitleController = TextEditingController();

  @override
  void dispose() {
    _quickTitleController.dispose();
    super.dispose();
  }

  void _showCreateTaskDialog(BuildContext context) {
    final titleController = TextEditingController();
    final noteController = TextEditingController();
    String priority = 'P1';
    String workload = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '新建待办任务',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '想在今天专注完成什么？',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.marsGreen, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '备忘或具体步骤（选填）',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        '艾利优先级：',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      ...['P1', 'P2', 'P3', 'P4'].map((p) {
                        final isSelected = priority == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: isSelected,
                            selectedColor: AppTheme.priorityColor(p).withOpacity(0.18),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppTheme.priorityColor(p) : AppTheme.textSecondary,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => priority = p);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.trim().isEmpty) return;
                        context.read<TaskProvider>().addTask(
                              title: titleController.text,
                              notes: noteController.text.isEmpty ? null : noteController.text,
                              priority: priority,
                              workload: workload,
                            );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.marsGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('立即创建', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final monthDayStr = '${now.month}月${now.day}日 星期${weekdays[now.weekday - 1]}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProv, child) {
            final tasks = taskProv.tasks;

            return CustomScrollView(
              slivers: [
                // 顶部 Things 3 纯白通透标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthDayStr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.marsGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.marsGreen.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.marsGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${taskProv.completedCount}/${taskProv.totalCount}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.marsGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '今日',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 周历指示胶囊
                        _buildWeekStrip(),
                        const SizedBox(height: 16),

                        // 快速添加输入胶囊
                        _buildQuickAddBar(context),
                        const SizedBox(height: 16),

                        // 筛选过滤器
                        _buildFilterRow(taskProv),
                      ],
                    ),
                  ),
                ),

                // 任务列表
                if (taskProv.isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.marsGreen),
                    ),
                  )
                else if (tasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.spa_outlined, size: 56, color: Colors.black.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          const Text(
                            '今天的所有任务都已完成',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '享受内心的从容与平静',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final task = tasks[index];
                          return _buildTaskCard(context, task);
                        },
                        childCount: tasks.length,
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context),
        backgroundColor: AppTheme.marsGreen,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final date = startOfWeek.add(Duration(days: i));
          final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
          const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: isToday ? AppTheme.marsGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  weekdays[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: isToday ? Colors.white70 : AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuickAddBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.add_circle_outline, color: AppTheme.marsGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _quickTitleController,
              decoration: const InputDecoration(
                hintText: '快速添加今日要事...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onSubmitted: (text) {
                if (text.trim().isEmpty) return;
                context.read<TaskProvider>().addTask(title: text);
                _quickTitleController.clear();
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: AppTheme.marsGreen),
            onPressed: () {
              final text = _quickTitleController.text;
              if (text.trim().isEmpty) return;
              context.read<TaskProvider>().addTask(title: text);
              _quickTitleController.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(TaskProvider provider) {
    return Row(
      children: [
        _filterPill('全部', TaskFilter.all, provider),
        const SizedBox(width: 8),
        _filterPill('进行中', TaskFilter.pending, provider),
        const SizedBox(width: 8),
        _filterPill('已完成', TaskFilter.completed, provider),
      ],
    );
  }

  Widget _filterPill(String label, TaskFilter filter, TaskProvider provider) {
    final isActive = provider.currentFilter == filter;
    return GestureDetector(
      onTap: () => provider.setFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.marsGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.marsGreen : AppTheme.borderLight,
            width: isActive ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.marsGreen : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final pColor = AppTheme.priorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.read<TaskProvider>().toggleTask(task.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 复选框
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: task.isCompleted ? AppTheme.marsGreen : Colors.white,
                    border: Border.all(
                      color: task.isCompleted ? AppTheme.marsGreen : Colors.black26,
                      width: 1.5,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),

                // 标题与副标题
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: task.isCompleted ? AppTheme.textMuted : AppTheme.textPrimary,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: AppTheme.textMuted,
                        ),
                      ),
                      if (task.notes != null && task.notes!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 优先级标识
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: pColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: pColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 快捷关联专注按钮
                IconButton(
                  icon: const Icon(Icons.timer_outlined, size: 18, color: AppTheme.textMuted),
                  visualDensity: VisualDensity.compact,
                  tooltip: '以此任务开始专注',
                  onPressed: () {
                    context.read<PomodoroProvider>().selectTask(task.id, task.title);
                    if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(1); // 切换至专注 Tab
                    }
                  },
                ),

                // 删除菜单
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: AppTheme.priorityP1),
                          SizedBox(width: 8),
                          Text('删除任务', style: TextStyle(color: AppTheme.priorityP1)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (val) {
                    if (val == 'delete') {
                      context.read<TaskProvider>().deleteTask(task.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
