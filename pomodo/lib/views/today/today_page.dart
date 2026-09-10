import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';
import 'task_detail_sheet.dart';

/// 100% 像素级对齐设计稿的「今日待办」页面
/// 架构特性：
/// 1. Things 3 风格纯白通透空气感大标题 + POMODO 品牌标识 + 离线单机·SQLite 状态胶囊
/// 2. 通透极简周历条 (无外层卡片框，自然悬浮)
/// 3. Pure Task Card 雅致纯净任务流（圆形极简 Checkbox、⏰ 时间·标签、🍅 专注直达、艾利法 1~5 序号）
/// 4. 方案 C 悬浮灵动输入胶囊 (Floating Pill Dock)，回车入列 + 圆形加号呼出完整属性抽屉
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

  @override
  void dispose() {
    _quickTitleController.dispose();
    super.dispose();
  }

  void _quickAddSubmit(BuildContext context) {
    final text = _quickTitleController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    context.read<TaskProvider>().addTask(
          title: text,
          dueDate: isToday ? null : dateStr,
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
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    final monthDayStr =
        '${_selectedDate.month}月${_selectedDate.day}日 星期${weekdays[_selectedDate.weekday - 1]}';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Consumer<TaskProvider>(
          builder: (context, taskProv, child) {
            final tasks = taskProv.tasksForDate(_selectedDate);

            return Stack(
              children: [
                CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // 1. Things 3 纯白通透标题区
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 顶栏：● POMODO 品牌标
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.marsGreen,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'POMODO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.marsGreen,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // 大标题：今日待办 (或 X日待办)
                            Row(
                              children: [
                                Text(
                                  isSelectedToday ? '今日待办' : '${_selectedDate.day}日待办',
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6,
                                    color: Color(0xFF0F172A),
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
                                        color: AppTheme.marsGreen.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppTheme.marsGreen.withOpacity(0.3)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.today_rounded,
                                              size: 12, color: AppTheme.marsGreen),
                                          SizedBox(width: 4),
                                          Text(
                                            '回今天',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.marsGreen,
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

                            // 副标题：9月9日 星期三 · 4 个待办事项
                            Text(
                              '$monthDayStr · ${tasks.length} 个待办事项',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 2. Things 3 风格极简周历条 (通透悬浮，无外包卡片框)
                    SliverToBoxAdapter(
                      child: _buildWeekStrip(taskProv),
                    ),

                    // 3. 任务列表流
                    if (taskProv.isLoading)
                      const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.marsGreen),
                        ),
                      )
                    else if (tasks.isEmpty)
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
                                color: const Color(0xFF94A3B8).withOpacity(0.4),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isSelectedToday
                                    ? '今天的所有任务都已完成'
                                    : '${_selectedDate.month}月${_selectedDate.day}日 暂无日程任务',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isSelectedToday
                                    ? '享受内心的从容与专注'
                                    : '在下方灵动输入框或点击 + 为该日规划要事',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              if (!isSelectedToday) ...[
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final n = DateTime.now();
                                    setState(() => _selectedDate =
                                        DateTime(n.year, n.month, n.day));
                                  },
                                  icon: const Icon(Icons.arrow_back_rounded,
                                      size: 14, color: AppTheme.marsGreen),
                                  label: const Text(
                                    '返回今日待办',
                                    style: TextStyle(
                                      color: AppTheme.marsGreen,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppTheme.marsGreen),
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
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final task = tasks[index];
                              return _buildPureTaskCard(context, task);
                            },
                            childCount: tasks.length,
                          ),
                        ),
                      ),
                  ],
                ),

                // 4. 方案 C 悬浮灵动输入胶囊 (Floating Pill Dock)
                _buildFloatingPillDock(context),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Things 3 风格极简周历条 (通透无压迫，轻微底部细分割线)
  Widget _buildWeekStrip(TaskProvider taskProv) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
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
            final hasTasks = taskProv.hasTasksOnDate(date);
            const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

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
                      weekdays[i],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.marsGreen : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.marsGreen.withOpacity(0.32),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    // 任务小圆点
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasTasks
                            ? (isSelected
                                ? AppTheme.marsGreen
                                : AppTheme.marsGreen.withOpacity(0.8))
                            : (isToday
                                ? const Color(0xFFCBD5E1)
                                : Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Things 3 / Linear 雅致纯净任务卡片 (Pure Task Card)
  Widget _buildPureTaskCard(BuildContext context, Task task) {
    final isDone = task.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFFF1F5F9) : const Color(0xFFF1F5F9),
        ),
        boxShadow: isDone
            ? []
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.03),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
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
                  onTap: () {
                    context.read<TaskProvider>().toggleTask(task.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppTheme.marsGreen : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppTheme.marsGreen : const Color(0xFFCBD5E1),
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
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (task.dueDate != null) ...[
                            Text(
                              '⏰ ${task.dueDate!.substring(5)}',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const Text(' · ',
                                style:
                                    TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                          Builder(builder: (ctx) {
                            final taskProv = ctx.watch<TaskProvider>();
                            final cat = taskProv.getCategoryById(task.categoryId);
                            final catName = cat?.name ??
                                (task.categoryId == null ? '工作与工程' : '未命名清单');
                            final catColor =
                                cat?.uiColor ?? const Color(0xFF008779);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: catColor.withOpacity(0.1),
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
                          if (task.notes != null && task.notes!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Text('📝', style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 右侧操作簇: 方案 A 快捷直达 🍅 专注 + 艾利序号
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final pomoProv = context.read<PomodoroProvider>();
                        pomoProv.selectTask(task.id, task.title);
                        pomoProv.start();
                        widget.onNavigateTab?.call(1);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x2E008779)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🍅', style: TextStyle(fontSize: 11)),
                            SizedBox(width: 3),
                            Text(
                              '专注',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.marsGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // 艾利法序号：等宽弱字，不刺眼
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${task.ivyOrder}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
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

  /// 方案 C：悬浮灵动输入胶囊 (Floating Pill Dock · Linear / Things 风格)
  Widget _buildFloatingPillDock(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 5, 6, 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0).withOpacity(0.85)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: '+ 快速记录待办，按 Enter 入列...',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _quickAddSubmit(context),
              ),
            ),
            const SizedBox(width: 8),
            // 右侧绿色圆圈 + 号按钮，展开完整属性抽屉
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
                  color: AppTheme.marsGreen,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.marsGreen.withOpacity(0.35),
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
}
