import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../models/task.dart';
import '../models/category.dart';

enum TaskFilter { all, pending, completed }

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Task> _tasks = [];
  List<Category> _categories = [];
  Map<String, int> _categoryTaskCounts = {};
  Map<String, ({int total, int completed})> _subtaskProgress = {};
  Map<String, ({int count, int minutes})> _taskPomoSummary = {};
  TaskFilter _currentFilter = TaskFilter.all;
  String? _selectedCategoryId;
  bool _isLoading = false;

  List<Category> get categories => _categories;
  Map<String, int> get categoryTaskCounts => _categoryTaskCounts;
  String? get selectedCategoryId => _selectedCategoryId;
  Map<String, ({int count, int minutes})> get taskPomoSummary => _taskPomoSummary;

  @visibleForTesting
  void setTasksForTesting(List<Task> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  List<Task> get tasks {
    switch (_currentFilter) {
      case TaskFilter.pending:
        return _tasks.where((t) => !t.isCompleted).toList();
      case TaskFilter.completed:
        return _tasks.where((t) => t.isCompleted).toList();
      case TaskFilter.all:
        return _tasks;
    }
  }

  List<Task> get ivyLeeTasks {
    return _tasks
        .where((t) => !t.isCompleted)
        .take(5)
        .toList();
  }

  TaskFilter get currentFilter => _currentFilter;
  bool get isLoading => _isLoading;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  double get completionRate => totalCount == 0 ? 0.0 : (completedCount / totalCount);

  /// 历史所有已完成任务（按完成时间倒序）
  List<Task> get allCompletedTasks {
    final list = _tasks.where((t) => t.isCompleted).toList();
    list.sort((a, b) {
      final aTime = a.completedAt ?? a.updatedAt;
      final bTime = b.completedAt ?? b.updatedAt;
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// 获取指定任务的子任务完成进度：({int total, int completed})
  ({int total, int completed})? getSubtaskProgress(String taskId) {
    return _subtaskProgress[taskId];
  }

  /// 获取指定任务关联的已完成番茄专注统计：({int count, int minutes})
  ({int count, int minutes})? getTaskPomoSummary(String taskId) {
    return _taskPomoSummary[taskId];
  }

  /// 快速刷新任务番茄统计
  Future<void> refreshPomoSummary() async {
    try {
      _taskPomoSummary = await _dbHelper.getTaskPomoSummary();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing pomo summary: $e');
    }
  }

  /// 快速筛选分类
  void selectCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) {
      _selectedCategoryId = null; // 再次点击同一分类取消筛选
    } else {
      _selectedCategoryId = categoryId;
    }
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _dbHelper.getAllTasks();
      _categories = await _dbHelper.getAllCategories();
      _categoryTaskCounts = await _dbHelper.getCategoryTaskCounts();
      _subtaskProgress = await _dbHelper.getSubtaskProgressSummary();
      _taskPomoSummary = await _dbHelper.getTaskPomoSummary();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(TaskFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// 收集箱待办任务：未设置截止日期且未完成
  List<Task> get inboxTasks {
    return _tasks.where((t) => t.dueDate == null && !t.isCompleted).toList();
  }

  int get inboxCount => inboxTasks.length;

  /// 根据日期过滤任务（Things 3 纯粹双轨流：今日严格只收纳今日截止或顺延未完成项，无日期项归入收集箱）
  List<Task> tasksForDate(
    DateTime date, {
    bool autoRollover = true,
    String? categoryId,
  }) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final targetCategory = categoryId ?? _selectedCategoryId;

    return tasks.where((t) {
      // 分类过滤
      if (targetCategory != null && t.categoryId != targetCategory) {
        return false;
      }

      if (isToday) {
        // 1. 明确设定为今日截止的任务
        if (t.dueDate == dateStr) return true;
        // 2. 历史过期未完成任务，若启用了 autoRollover 则顺延至今日
        if (autoRollover && !t.isCompleted && t.dueDate != null && t.dueDate!.compareTo(dateStr) < 0) {
          return true;
        }
        // 无日期 (dueDate == null) 属于收集箱 (Inbox)，不混入今日
        return false;
      } else {
        // 非今日：只展示截止日期为当天的，或者在该天被完成的
        if (t.dueDate == dateStr) return true;
        if (t.completedAt != null && t.completedAt!.startsWith(dateStr)) return true;
        return false;
      }
    }).toList();
  }

  bool hasTasksOnDate(DateTime date, {bool autoRollover = true}) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    return _tasks.any((t) {
      if (isToday) {
        if (t.dueDate == dateStr) return true;
        if (autoRollover && !t.isCompleted && t.dueDate != null && t.dueDate!.compareTo(dateStr) < 0) {
          return true;
        }
        return false;
      } else {
        return t.dueDate == dateStr || (t.completedAt != null && t.completedAt!.startsWith(dateStr));
      }
    });
  }

  /// 将收集箱任务排期到指定日期（默认为今日）
  Future<void> scheduleTaskToDate(String taskId, [DateTime? targetDate]) async {
    final date = targetDate ?? DateTime.now();
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _tasks[index].copyWith(
        dueDate: dateStr,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _dbHelper.updateTask(updated);
      _tasks[index] = updated;
      notifyListeners();
    }
  }

  /// 将任务移回收集箱（清除截止日期）
  Future<void> moveTaskToInbox(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updated = _tasks[index].copyWith(
        clearDueDate: true,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _dbHelper.updateTask(updated);
      _tasks[index] = updated;
      notifyListeners();
    }
  }

  Future<Task> addTask({
    required String title,
    String? notes,
    String priority = 'P1',
    String workload = 'easy',
    int? ivyOrder,
    String? dueDate,
    String? categoryId,
  }) async {
    final now = DateTime.now().toIso8601String();
    final nextIvy = ivyOrder ?? (_tasks.where((t) => !t.isCompleted).length + 1);

    final newTask = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      notes: notes?.trim(),
      priority: priority,
      ivyOrder: nextIvy,
      status: 'pending',
      workload: workload,
      dueDate: dueDate,
      categoryId: categoryId,
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.insertTask(newTask);
    await loadTasks();
    return newTask;
  }

  Future<void> toggleTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final currentTask = _tasks[index];
    final isDone = currentTask.isCompleted;
    final now = DateTime.now().toIso8601String();

    final updatedTask = currentTask.copyWith(
      status: isDone ? 'pending' : 'completed',
      completedAt: isDone ? null : now,
      updatedAt: now,
    );

    // 乐观更新 UI
    _tasks[index] = updatedTask;
    notifyListeners();

    await _dbHelper.updateTask(updatedTask);
    await loadTasks();
  }

  /// 恢复已完成任务为未完成进行中
  Future<void> reopenTask(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final currentTask = _tasks[index];
    final now = DateTime.now().toIso8601String();
    final updated = currentTask.copyWith(
      status: 'pending',
      clearCompletedAt: true,
      updatedAt: now,
    );

    _tasks[index] = updated;
    notifyListeners();

    await _dbHelper.updateTask(updated);
    await loadTasks();
  }

  final Map<String, List<String>> _deletedTaskSessionsCache = {};

  Future<void> deleteTask(String id) async {
    // 缓存可能关联的番茄记录 ID，用于 4 秒内撤销恢复时原子重连
    try {
      final sessionIds = await _dbHelper.getSessionIdsForTask(id);
      if (sessionIds.isNotEmpty) {
        _deletedTaskSessionsCache[id] = sessionIds;
      }
    } catch (_) {}

    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();

    await _dbHelper.deleteTask(id);
    await loadTasks();
  }

  /// 撤销删除：恢复任务与其子任务，并重连历史番茄资产
  Future<void> restoreTask(Task task, List<Subtask> subtasks) async {
    final cachedSessionIds = _deletedTaskSessionsCache.remove(task.id);
    await _dbHelper.restoreTask(task, subtasks, cachedSessionIds);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now().toIso8601String());
    await _dbHelper.updateTask(updated);
    await loadTasks();
  }

  // === 子任务管理 ===
  Future<List<Subtask>> getSubtasks(String taskId) async {
    return await _dbHelper.getSubtasks(taskId);
  }

  Future<Subtask> addSubtask(String taskId, String title) async {
    final subtasks = await _dbHelper.getSubtasks(taskId);
    final newSubtask = Subtask(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      title: title.trim(),
      sortOrder: subtasks.length + 1,
    );
    await _dbHelper.insertSubtask(newSubtask);
    _subtaskProgress = await _dbHelper.getSubtaskProgressSummary();
    notifyListeners();
    return newSubtask;
  }

  Future<void> toggleSubtask(Subtask subtask) async {
    final updated = Subtask(
      id: subtask.id,
      taskId: subtask.taskId,
      title: subtask.title,
      isCompleted: !subtask.isCompleted,
      sortOrder: subtask.sortOrder,
    );
    await _dbHelper.updateSubtask(updated);
    _subtaskProgress = await _dbHelper.getSubtaskProgressSummary();
    notifyListeners();
  }

  Future<void> deleteSubtask(String id) async {
    await _dbHelper.deleteSubtask(id);
    _subtaskProgress = await _dbHelper.getSubtaskProgressSummary();
    notifyListeners();
  }

  /// 艾利法则拖拽调序：针对指定任务流安全重排
  Future<void> reorderIvyTasks(int oldIndex, int newIndex, List<Task> currentPendingTasks) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (oldIndex >= currentPendingTasks.length ||
        newIndex >= currentPendingTasks.length ||
        oldIndex < 0 ||
        newIndex < 0) {
      return;
    }

    final item = currentPendingTasks.removeAt(oldIndex);
    currentPendingTasks.insert(newIndex, item);

    // 1. 内存乐观即时生效
    for (int i = 0; i < currentPendingTasks.length; i++) {
      final taskIndex = _tasks.indexWhere((t) => t.id == currentPendingTasks[i].id);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(ivyOrder: i + 1);
      }
    }
    notifyListeners();

    // 2. 异步持久化至 SQLite
    for (int i = 0; i < currentPendingTasks.length; i++) {
      final updated = currentPendingTasks[i].copyWith(ivyOrder: i + 1);
      await _dbHelper.updateTask(updated);
    }
    await loadTasks();
  }

  // === 分类管理 (Category Management) ===
  Future<void> loadCategories() async {
    try {
      _categories = await _dbHelper.getAllCategories();
      _categoryTaskCounts = await _dbHelper.getCategoryTaskCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Category? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  String getCategoryName(String? id) {
    final cat = getCategoryById(id);
    return cat?.name ?? '工作与工程';
  }

  Color getCategoryColor(String? id) {
    final cat = getCategoryById(id);
    return cat?.uiColor ?? const Color(0xFF008779);
  }

  Future<Category> addCategory({
    required String name,
    required String color,
    String? icon,
  }) async {
    final newCat = Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      color: color,
      icon: icon ?? 'folder',
      sortOrder: _categories.length + 1,
    );
    await _dbHelper.insertCategory(newCat);
    await loadCategories();
    return newCat;
  }

  Future<void> updateCategory(Category category) async {
    await _dbHelper.updateCategory(category);
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _dbHelper.deleteCategory(id);
    await loadTasks();
    await loadCategories();
  }
}
