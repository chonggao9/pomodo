import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../providers/pomodoro_provider.dart';

/// 1:1 还原设计稿的完整任务属性抽屉 (Task Detail Sheet)
class TaskDetailSheet extends StatefulWidget {
  final Task? task; // null 为新建任务，非 null 为编辑详情
  final DateTime initialDate;
  final Function(int)? onNavigateTab;

  const TaskDetailSheet({
    super.key,
    this.task,
    required this.initialDate,
    this.onNavigateTab,
  });

  static Future<void> show(
    BuildContext context, {
    Task? task,
    required DateTime initialDate,
    Function(int)? onNavigateTab,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(
        task: task,
        initialDate: initialDate,
        onNavigateTab: onNavigateTab,
      ),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _subtaskInputController;

  String _category = '工作清单';
  String _workload = 'hard'; // 'easy' (一般), 'medium' (中等难度), 'hard' (较高难度)
  String? _dueDate;
  String _dateChoice = '今天'; // '今天', '明天', '选择日期', '没有日期'
  String _priority = 'P1';

  List<Subtask> _subtasks = [];
  bool _isAddingSubtask = false;
  String? _reminderTime;
  bool _isRepeat = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _subtaskInputController = TextEditingController();

    if (task != null) {
      _workload = task.workload;
      _priority = task.priority;
      _dueDate = task.dueDate;
      _initDateChoiceFromDueDate(_dueDate);
      _loadSubtasks(task.id);
    } else {
      _initDefaultDateChoice();
    }
  }

  void _initDateChoiceFromDueDate(String? dueDate) {
    if (dueDate == null) {
      _dateChoice = '没有日期';
      return;
    }
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    if (dueDate == todayStr) {
      _dateChoice = '今天';
    } else if (dueDate == tomorrowStr) {
      _dateChoice = '明天';
    } else {
      _dateChoice = '选择日期';
    }
  }

  void _initDefaultDateChoice() {
    final now = DateTime.now();
    final isToday = widget.initialDate.year == now.year &&
        widget.initialDate.month == now.month &&
        widget.initialDate.day == now.day;

    if (isToday) {
      _dateChoice = '今天';
      _dueDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else {
      _dateChoice = '选择日期';
      _dueDate =
          '${widget.initialDate.year}-${widget.initialDate.month.toString().padLeft(2, '0')}-${widget.initialDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _loadSubtasks(String taskId) async {
    final list = await context.read<TaskProvider>().getSubtasks(taskId);
    if (mounted) {
      setState(() => _subtasks = list);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _subtaskInputController.dispose();
    super.dispose();
  }

  Future<Task?> _saveTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return null;

    final taskProv = context.read<TaskProvider>();
    final notes = _notesController.text.trim();

    if (widget.task != null) {
      final updated = widget.task!.copyWith(
        title: title,
        notes: notes.isEmpty ? null : notes,
        workload: _workload,
        dueDate: _dueDate,
        priority: _priority,
      );
      await taskProv.updateTask(updated);
      return updated;
    } else {
      final created = await taskProv.addTask(
        title: title,
        notes: notes.isEmpty ? null : notes,
        priority: _priority,
        workload: _workload,
        dueDate: _dueDate,
      );

      // 如果有临时创建的子任务，批量写入
      for (final sub in _subtasks) {
        await taskProv.addSubtask(created.id, sub.title);
      }
      return created;
    }
  }

  void _onDatePillTap(String choice) async {
    final now = DateTime.now();
    if (choice == '今天') {
      setState(() {
        _dateChoice = '今天';
        _dueDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      });
    } else if (choice == '明天') {
      final tomorrow = now.add(const Duration(days: 1));
      setState(() {
        _dateChoice = '明天';
        _dueDate =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      });
    } else if (choice == '没有日期') {
      setState(() {
        _dateChoice = '没有日期';
        _dueDate = null;
      });
    } else if (choice == '选择日期') {
      final picked = await showDatePicker(
        context: context,
        initialDate: widget.initialDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.marsGreen,
                onPrimary: Colors.white,
                onSurface: Color(0xFF0F172A),
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          _dateChoice = '选择日期';
          _dueDate =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        });
      }
    }
  }

  void _addSubtaskInline() async {
    final title = _subtaskInputController.text.trim();
    if (title.isEmpty) {
      setState(() => _isAddingSubtask = false);
      return;
    }

    if (widget.task != null) {
      await context.read<TaskProvider>().addSubtask(widget.task!.id, title);
      await _loadSubtasks(widget.task!.id);
    } else {
      // 临时加入本地列表，待任务创建时统一写入
      setState(() {
        _subtasks.add(
          Subtask(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            taskId: '',
            title: title,
          ),
        );
      });
    }
    _subtaskInputController.clear();
    setState(() => _isAddingSubtask = false);
  }

  void _startPomodoroFocus() async {
    final saved = await _saveTask();
    if (saved == null) return;

    if (!mounted) return;
    // 载入当前任务并直接开始倒计时
    final pomoProv = context.read<PomodoroProvider>();
    pomoProv.selectTask(saved.id, saved.title);
    pomoProv.start();

    Navigator.pop(context);
    widget.onNavigateTab?.call(1); // 切换至专注 Tab
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 10,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部物理手柄条
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 顶行：左侧「● 工作清单」+ 右侧「保存到本地」与「✕」
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 清单标签
              InkWell(
                onTap: () {
                  setState(() {
                    _category = _category == '工作清单' ? '生活与健康' : '工作清单';
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.marsGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              // 右侧保存与关闭操作
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await _saveTask();
                      nav.pop();
                    },
                    child: const Text(
                      '保存到本地',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.marsGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 任务标题输入框 (大字粗体)
          TextField(
            controller: _titleController,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
            decoration: const InputDecoration(
              hintText: '想在今天专注完成什么？',
              hintStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),

          // 描述备注输入框
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
            decoration: const InputDecoration(
              hintText: '添加描述或注意事项 (纯本地存储)...',
              hintStyle: TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          // 快捷日期胶囊组: 今天 | 明天 | 选择日期 ∨ | 没有日期
          _buildDatePillsRow(),
          const SizedBox(height: 14),

          // 子任务清单模块
          _buildSubtasksSection(),
          const SizedBox(height: 14),

          // 艾利工作量评估 (一般 / 中等难度 / 较高难度)
          _buildWorkloadSection(),
          const SizedBox(height: 16),

          // 沉浸专注大按钮
          _buildStartFocusButton(),
          const SizedBox(height: 14),

          // 底部工具栏 (提醒时间 / 重复 / 更多)
          _buildBottomTools(),
        ],
      ),
    );
  }

  Widget _buildDatePillsRow() {
    final pills = [
      {'label': '今天', 'key': '今天'},
      {'label': '明天', 'key': '明天'},
      {
        'label': _dateChoice == '选择日期' && _dueDate != null
            ? '${_dueDate!.substring(5)} ∨'
            : '选择日期 ∨',
        'key': '选择日期'
      },
      {'label': '没有日期', 'key': '没有日期'},
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: pills.map((p) {
        final isSelected = _dateChoice == p['key'];
        return GestureDetector(
          onTap: () => _onDatePillTap(p['key']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.marsGreen : const Color(0xFFF1F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              p['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubtasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_subtasks.isNotEmpty) ...[
          ..._subtasks.map((sub) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (widget.task != null) {
                          await context.read<TaskProvider>().toggleSubtask(sub);
                          await _loadSubtasks(widget.task!.id);
                        } else {
                          setState(() {
                            final idx = _subtasks.indexOf(sub);
                            _subtasks[idx] = Subtask(
                              id: sub.id,
                              taskId: sub.taskId,
                              title: sub.title,
                              isCompleted: !sub.isCompleted,
                            );
                          });
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            sub.isCompleted
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            size: 15,
                            color: sub.isCompleted
                                ? AppTheme.marsGreen
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sub.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: sub.isCompleted
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF334155),
                                decoration: sub.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      if (widget.task != null) {
                        await context.read<TaskProvider>().deleteSubtask(sub.id);
                        await _loadSubtasks(widget.task!.id);
                      } else {
                        setState(() => _subtasks.remove(sub));
                      }
                    },
                    child: const Icon(Icons.close, size: 14, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            );
          }),
        ],

        // 内联输入或按钮
        if (_isAddingSubtask) ...[
          Row(
            children: [
              const Icon(Icons.add, size: 15, color: AppTheme.marsGreen),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _subtaskInputController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                  decoration: const InputDecoration(
                    hintText: '输入子任务名称，按完成键添加',
                    hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                  onSubmitted: (_) => _addSubtaskInline(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, size: 16, color: AppTheme.marsGreen),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _addSubtaskInline,
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _isAddingSubtask = true),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '+ 添加子任务项',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.marsGreen,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkloadSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEF2F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '艾利工作量评估',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFE8ECEF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _workloadChoiceItem('一般', 'easy'),
                _workloadChoiceItem('中等难度', 'medium'),
                _workloadChoiceItem('较高难度', 'hard'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workloadChoiceItem(String label, String value) {
    final isSelected = _workload == value;
    Color activeColor = AppTheme.marsGreen;
    if (value == 'hard') {
      activeColor = const Color(0xFFEF4444); // 珊瑚红 / 艾利高难度红
    }

    return GestureDetector(
      onTap: () => setState(() => _workload = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildStartFocusButton() {
    return GestureDetector(
      onTap: _startPomodoroFocus,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF008779), Color(0xFF005C53)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.marsGreen.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: Colors.white),
            SizedBox(width: 8),
            Text(
              '开始当前任务沉浸专注 (25m)',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTools() {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // 提醒时间胶囊
              GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    setState(() {
                      _reminderTime =
                          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _reminderTime != null
                        ? AppTheme.marsGreen.withOpacity(0.12)
                        : const Color(0xFFF1F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _reminderTime != null ? '⏰ $_reminderTime' : '⏰ 提醒',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _reminderTime != null
                              ? AppTheme.marsGreen
                              : const Color(0xFF64748B),
                        ),
                      ),
                      if (_reminderTime != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _reminderTime = null),
                          child: const Icon(Icons.close, size: 12, color: AppTheme.marsGreen),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 重复胶囊
              GestureDetector(
                onTap: () => setState(() => _isRepeat = !_isRepeat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isRepeat
                        ? AppTheme.marsGreen.withOpacity(0.12)
                        : const Color(0xFFF1F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 12,
                        color: _isRepeat ? AppTheme.marsGreen : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '重复',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isRepeat ? AppTheme.marsGreen : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 更多操作
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, size: 20, color: Color(0xFF94A3B8)),
            padding: EdgeInsets.zero,
            onSelected: (val) async {
              if (val == 'delete' && widget.task != null) {
                final nav = Navigator.of(context);
                await context.read<TaskProvider>().deleteTask(widget.task!.id);
                nav.pop();
              }
            },
            itemBuilder: (ctx) => [
              if (widget.task != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      SizedBox(width: 8),
                      Text('删除此任务', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
