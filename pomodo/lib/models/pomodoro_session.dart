class PomodoroSession {
  final String id;
  final String? taskId;
  final int durationMinutes;
  final String startedAt;
  final String? endedAt;
  final String status; // completed, interrupted
  final String? notes;

  PomodoroSession({
    required this.id,
    this.taskId,
    required this.durationMinutes,
    required this.startedAt,
    this.endedAt,
    this.status = 'completed',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'duration_minutes': durationMinutes,
      'started_at': startedAt,
      'ended_at': endedAt,
      'status': status,
      'notes': notes,
    };
  }

  factory PomodoroSession.fromMap(Map<String, dynamic> map) {
    return PomodoroSession(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      durationMinutes: (map['duration_minutes'] as int?) ?? 25,
      startedAt: map['started_at'] as String,
      endedAt: map['ended_at'] as String?,
      status: (map['status'] as String?) ?? 'completed',
      notes: map['notes'] as String?,
    );
  }
}
