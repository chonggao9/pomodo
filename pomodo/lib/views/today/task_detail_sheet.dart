import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_strings.dart';
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

  String? _categoryId;
  String _workload = 'hard'; // 'easy', 'medium', 'hard'
  String? _dueDate;
  String _dateChoice = 'today'; // 'today', 'tomorrow', 'custom', 'none'
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
      _categoryId = task.categoryId;
      _initDateChoiceFromDueDate(_dueDate);
      _loadSubtasks(task.id);
    } else {
      _initDefaultDateChoice();
    }
  }

  void _initDateChoiceFromDueDate(String? dueDate) {
    if (dueDate == null) {
      _dateChoice = 'none';
      return;
    }
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    if (dueDate == todayStr) {
      _dateChoice = 'today';
    } else if (dueDate == tomorrowStr) {
      _dateChoice = 'tomorrow';
    } else {
      _dateChoice = 'custom';
    }
  }

  void _initDefaultDateChoice() {
    final now = DateTime.now();
    final isToday = widget.initialDate.year == now.year &&
        widget.initialDate.month == now.month &&
        widget.initialDate.day == now.day;

    if (isToday) {
      _dateChoice = 'today';
      _dueDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else {
      _dateChoice = 'custom';
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
        categoryId: _categoryId,
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
        categoryId: _categoryId,
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
    if (choice == 'today') {
      setState(() {
        _dateChoice = 'today';
        _dueDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      });
    } else if (choice == 'tomorrow') {
      final tomorrow = now.add(const Duration(days: 1));
      setState(() {
        _dateChoice = 'tomorrow';
        _dueDate =
            '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      });
    } else if (choice == 'none') {
      setState(() {
        _dateChoice = 'none';
        _dueDate = null;
      });
    } else if (choice == 'custom') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = Theme.of(context).primaryColor;
      final picked = await showDatePicker(
        context: context,
        initialDate: widget.initialDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: isDark
                  ? ColorScheme.dark(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      surface: AppTheme.darkBgSurface,
                      onSurface: AppTheme.darkTextMain,
                    )
                  : ColorScheme.light(
                      primary: primaryColor,
                      onPrimary: Colors.white,
                      onSurface: const Color(0xFF0F172A),
                    ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          _dateChoice = 'custom';
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
      final sub = await context.read<TaskProvider>().addSubtask(widget.task!.id, title);
      _subtaskInputController.clear();
      setState(() {
        _subtasks.add(sub);
        _isAddingSubtask = false;
      });
    } else {
      _subtaskInputController.clear();
      setState(() {
        _subtasks.add(Subtask(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          taskId: 'temp',
          title: title,
        ));
        _isAddingSubtask = false;
      });
    }
  }

  void _startPomodoroFocus() async {
    final saved = await _saveTask();
    if (saved == null || !mounted) return;

    final pomoProv = context.read<PomodoroProvider>();
    if (pomoProv.isRunning &&
        pomoProv.selectedTaskId != null &&
        pomoProv.selectedTaskId != saved.id) {
      final strings = AppStrings.of(context);
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
        saved.id,
        saved.title,
        saveCurrent: action == 'settle',
      );
    } else {
      pomoProv.selectTask(saved.id, saved.title);
      pomoProv.start();
    }

    if (mounted) {
      Navigator.pop(context);
      widget.onNavigateTab?.call(1); // 切换至专注 Tab
    }
  }

  void _showCategoryPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final taskProv = context.watch<TaskProvider>();
            final categories = taskProv.categories;
            final counts = taskProv.categoryTaskCounts;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkBgSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        strings.selectListTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showCreateCategoryDialog(context, taskProv);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 14, color: primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                strings.createListBtn,
                                style: TextStyle(
                                  fontSize: 12,
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
                  const SizedBox(height: 14),
                  if (categories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          strings.noListsPrompt,
                          style: TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (_, _) =>
                            Divider(height: 1, color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9)),
                        itemBuilder: (ctx, index) {
                          final cat = categories[index];
                          final isSelected = (_categoryId == cat.id) ||
                              (_categoryId == null && index == 0);
                          final pendingCount = counts[cat.id] ?? 0;

                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cat.uiColor,
                              ),
                            ),
                            title: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A)),
                              ),
                            ),
                            subtitle: Text(
                              '$pendingCount ${strings.itemsUnit}',
                              style: TextStyle(
                                  fontSize: 11, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_rounded,
                                    color: primaryColor, size: 20)
                                : null,
                            onTap: () {
                              setState(() {
                                _categoryId = cat.id;
                              });
                              Navigator.pop(sheetCtx);
                            },
                          );
                        },
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

  void _showCreateCategoryDialog(BuildContext context, TaskProvider taskProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);
    final nameController = TextEditingController();
    final colors = [
      '#008779', // 马尔斯绿
      '#0EA5E9', // 晴空蓝
      '#8B5CF6', // 丁香紫
      '#F59E0B', // 琥珀橙
      '#10B981', // 青提绿
      '#EF4444', // 珊瑚红
    ];
    String selectedColor = colors.first;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppTheme.darkBgSurface : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(strings.createCategoryTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                  )),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: TextStyle(color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: strings.categoryNameHint,
                      hintStyle:
                          TextStyle(fontSize: 13, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: primaryColor, width: 1.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(strings.isZh ? '选择标签颜色' : 'Select Color',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: colors.map((c) {
                      final isCurrent = selectedColor == c;
                      final colorObj =
                          Color(int.parse('FF${c.replaceAll('#', '')}', radix: 16));
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedColor = c);
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorObj,
                            border: Border.all(
                              color: isCurrent
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: isCurrent
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(strings.cancel, style: TextStyle(color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final navDialog = Navigator.of(dialogCtx);
                    final navPicker = Navigator.of(context);
                    final created = await taskProv.addCategory(
                      name: name,
                      color: selectedColor,
                    );
                    if (mounted) {
                      setState(() {
                        _categoryId = created.id;
                      });
                    }
                    navDialog.pop();
                    if (navPicker.canPop()) {
                      navPicker.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(strings.createAndSelectBtn),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final strings = AppStrings.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 10,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black12,
            blurRadius: 20,
            offset: const Offset(0, -4),
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
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 顶行：左侧「● 工作清单」+ 右侧「保存到本地」与「✕」
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 清单标签 (接入即选即建选择器)
              Builder(builder: (ctx) {
                final taskProv = ctx.watch<TaskProvider>();
                final currentCat = taskProv.getCategoryById(_categoryId);
                final currentCatName = currentCat?.name ??
                    (_categoryId == null && taskProv.categories.isNotEmpty
                        ? taskProv.categories.first.name
                        : strings.defaultCategoryName);
                final currentCatColor = currentCat?.uiColor ?? primaryColor;

                return InkWell(
                  onTap: () => _showCategoryPicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentCatColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currentCatName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            size: 16, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
                      ],
                    ),
                  ),
                );
              }),

              // 右侧保存与关闭操作
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final nav = Navigator.of(context);
                      await _saveTask();
                      nav.pop();
                    },
                    child: Text(
                      strings.saveToLocalBtn,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, size: 20, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 任务标题输入框 (大字粗体)
          TextField(
            controller: _titleController,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? AppTheme.darkTextMain : const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
            decoration: InputDecoration(
              hintText: widget.task == null ? strings.titlePlaceholder : strings.sheetEditTitle,
              hintStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
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
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText: strings.notesPlaceholder,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),

          // 快捷日期胶囊组: 今天 | 明天 | 选择日期 ∨ | 没有日期
          _buildDatePillsRow(isDark, primaryColor, strings),
          const SizedBox(height: 14),

          // 子任务清单模块
          _buildSubtasksSection(isDark, primaryColor, strings),
          const SizedBox(height: 14),

          // 艾利工作量评估 (一般 / 中等难度 / 较高难度)
          _buildWorkloadSection(isDark, primaryColor, strings),
          const SizedBox(height: 16),

          // 沉浸专注大按钮
          _buildStartFocusButton(isDark, primaryColor, strings),
          const SizedBox(height: 14),

          // 底部工具栏 (提醒时间 / 重复 / 更多)
          _buildBottomTools(isDark, primaryColor, strings),
        ],
      ),
    );
  }

  Widget _buildDatePillsRow(bool isDark, Color primaryColor, AppStrings strings) {
    final pills = [
      {'label': strings.choiceToday, 'key': 'today'},
      {'label': strings.choiceTomorrow, 'key': 'tomorrow'},
      {
        'label': _dateChoice == 'custom' && _dueDate != null
            ? '${_dueDate!.substring(5)} ∨'
            : '${strings.choicePickDate} ∨',
        'key': 'custom'
      },
      {'label': strings.choiceNoDate, 'key': 'none'},
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
              color: isSelected
                  ? primaryColor
                  : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F4F6)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              p['label']!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubtasksSection(bool isDark, Color primaryColor, AppStrings strings) {
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
                                ? primaryColor
                                : (isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1)),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              sub.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: sub.isCompleted
                                    ? (isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8))
                                    : (isDark ? AppTheme.darkTextMain : const Color(0xFF334155)),
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
                    child: Icon(Icons.close, size: 14, color: isDark ? AppTheme.darkTextMuted : const Color(0xFFCBD5E1)),
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
              Icon(Icons.add, size: 15, color: primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _subtaskInputController,
                  autofocus: true,
                  style: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMain : const Color(0xFF334155)),
                  decoration: InputDecoration(
                    hintText: strings.addSubtaskHint,
                    hintStyle: TextStyle(fontSize: 12, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  onSubmitted: (_) => _addSubtaskInline(),
                ),
              ),
              IconButton(
                icon: Icon(Icons.check, size: 16, color: primaryColor),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: _addSubtaskInline,
              ),
            ],
          ),
        ] else ...[
          GestureDetector(
            onTap: () => setState(() => _isAddingSubtask = true),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '+ ${strings.subtasksLabel}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkloadSection(bool isDark, Color primaryColor, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBgPage : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppTheme.darkBorder : const Color(0xFFEEF2F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            strings.workloadEstimateLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF334155),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkBgSurface : const Color(0xFFE8ECEF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _workloadChoiceItem(strings.workloadEasy, 'easy', isDark, primaryColor),
                _workloadChoiceItem(strings.workloadMedium, 'medium', isDark, primaryColor),
                _workloadChoiceItem(strings.workloadHard, 'hard', isDark, primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workloadChoiceItem(String label, String value, bool isDark, Color primaryColor) {
    final isSelected = _workload == value;
    Color activeColor = primaryColor;
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
            color: isSelected
                ? Colors.white
                : (isDark ? AppTheme.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildStartFocusButton(bool isDark, Color primaryColor, AppStrings strings) {
    return GestureDetector(
      onTap: _startPomodoroFocus,
      child: Container(
        width: double.infinity,
        height: 46,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              strings.startFocusNowBtn,
              style: const TextStyle(
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

  Widget _buildBottomTools(bool isDark, Color primaryColor, AppStrings strings) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9))),
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
                        ? primaryColor.withOpacity(isDark ? 0.2 : 0.12)
                        : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F4F6)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _reminderTime != null
                            ? '⏰ $_reminderTime'
                            : (strings.isZh ? '⏰ 提醒' : '⏰ Reminder'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _reminderTime != null
                              ? primaryColor
                              : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                        ),
                      ),
                      if (_reminderTime != null) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _reminderTime = null),
                          child: Icon(Icons.close, size: 12, color: primaryColor),
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
                        ? primaryColor.withOpacity(isDark ? 0.2 : 0.12)
                        : (isDark ? AppTheme.darkBgPage : const Color(0xFFF1F4F6)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 12,
                        color: _isRepeat ? primaryColor : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        strings.isZh ? '重复' : 'Repeat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _isRepeat ? primaryColor : (isDark ? AppTheme.darkTextSecondary : const Color(0xFF64748B)),
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
            icon: Icon(Icons.more_horiz, size: 20, color: isDark ? AppTheme.darkTextMuted : const Color(0xFF94A3B8)),
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
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(strings.deleteBtn, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
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
