import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/task.dart';

enum TaskFilter { all, pending, completed }

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Task> _tasks = [];
  TaskFilter _currentFilter = TaskFilter.all;
  bool _isLoading = false;

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

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _dbHelper.getAllTasks();
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

  Future<void> addTask({
    required String title,
    String? notes,
    String priority = 'P1',
    String workload = 'medium',
    int? ivyOrder,
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
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.insertTask(newTask);
    await loadTasks();
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

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();

    await _dbHelper.deleteTask(id);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now().toIso8601String());
    await _dbHelper.updateTask(updated);
    await loadTasks();
  }

  Future<void> reorderIvyTasks(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final pending = _tasks.where((t) => !t.isCompleted).toList();
    if (oldIndex >= pending.length || newIndex >= pending.length) return;

    final item = pending.removeAt(oldIndex);
    pending.insert(newIndex, item);

    for (int i = 0; i < pending.length; i++) {
      final updated = pending[i].copyWith(ivyOrder: i + 1);
      await _dbHelper.updateTask(updated);
    }
    await loadTasks();
  }
}
