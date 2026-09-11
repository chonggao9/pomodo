class Task {
  final String id;
  final String title;
  final String? notes;
  final String priority;
  final int ivyOrder;
  final String status; // pending, completed, archived
  final String workload; // easy, medium, hard
  final String? dueDate;
  final String? categoryId;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.priority = 'P1',
    this.ivyOrder = 1,
    this.status = 'pending',
    this.workload = 'easy',
    this.dueDate,
    this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'priority': priority,
      'ivy_order': ivyOrder,
      'status': status,
      'workload': workload,
      'due_date': dueDate,
      'category_id': categoryId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      priority: (map['priority'] as String?) ?? 'P1',
      ivyOrder: (map['ivy_order'] as int?) ?? 1,
      status: (map['status'] as String?) ?? 'pending',
      workload: (map['workload'] as String?) ?? 'easy',
      dueDate: map['due_date'] as String?,
      categoryId: map['category_id'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      completedAt: map['completed_at'] as String?,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    String? priority,
    int? ivyOrder,
    String? status,
    String? workload,
    String? dueDate,
    bool clearDueDate = false,
    String? categoryId,
    bool clearCategoryId = false,
    String? createdAt,
    String? updatedAt,
    String? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      ivyOrder: ivyOrder ?? this.ivyOrder,
      status: status ?? this.status,
      workload: workload ?? this.workload,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}

class Subtask {
  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int sortOrder;

  Subtask({
    required this.id,
    required this.taskId,
    required this.title,
    this.isCompleted = false,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_completed': isCompleted ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] as String,
      taskId: map['task_id'] as String,
      title: map['title'] as String,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}
