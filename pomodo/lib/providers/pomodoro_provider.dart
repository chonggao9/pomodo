import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';
import '../models/pomodoro_session.dart';

enum PomodoroState { idle, running, paused, completed }

class PomodoroProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int _targetMinutes = 25;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;

  String? _selectedTaskId;
  String? _selectedTaskTitle;
  DateTime? _sessionStartTime;
  String _selectedSound = '静音模式';

  final List<int> _presetMinutes = [15, 25, 35, 45];
  final List<String> _soundPresets = ['静音模式', '雨落窗台', '机械打字', '夜色篝火'];

  int get targetMinutes => _targetMinutes;
  int get remainingSeconds => _remainingSeconds;
  PomodoroState get state => _state;
  bool get isRunning => _state == PomodoroState.running;
  bool get isPaused => _state == PomodoroState.paused;
  String? get selectedTaskId => _selectedTaskId;
  String? get selectedTaskTitle => _selectedTaskTitle;
  String get selectedSound => _selectedSound;
  List<int> get presetMinutes => _presetMinutes;
  List<String> get soundPresets => _soundPresets;

  double get progress {
    final totalSeconds = _targetMinutes * 60;
    if (totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  void setTargetMinutes(int minutes) {
    if (_state == PomodoroState.running) return;
    _targetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _state = PomodoroState.idle;
    notifyListeners();
  }

  void setSelectedSound(String sound) {
    _selectedSound = sound;
    notifyListeners();
  }

  void selectTask(String? id, String? title) {
    _selectedTaskId = id;
    _selectedTaskTitle = title;
    notifyListeners();
  }

  void start() {
    if (_state == PomodoroState.running) return;

    if (_state == PomodoroState.idle) {
      _remainingSeconds = _targetMinutes * 60;
      _sessionStartTime = DateTime.now();
    }

    _state = PomodoroState.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _finishSession();
      }
    });
    notifyListeners();
  }

  void pause() {
    if (_state != PomodoroState.running) return;
    _timer?.cancel();
    _state = PomodoroState.paused;
    notifyListeners();
  }

  void resume() {
    start();
  }

  void reset() {
    _timer?.cancel();
    _remainingSeconds = _targetMinutes * 60;
    _state = PomodoroState.idle;
    _sessionStartTime = null;
    notifyListeners();
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    _state = PomodoroState.completed;

    final now = DateTime.now();
    final session = PomodoroSession(
      id: 'pomo_${now.millisecondsSinceEpoch}',
      taskId: _selectedTaskId,
      durationMinutes: _targetMinutes,
      startedAt: _sessionStartTime?.toIso8601String() ?? now.toIso8601String(),
      endedAt: now.toIso8601String(),
      status: 'completed',
      notes: _selectedTaskTitle != null ? '完成针对 [$_selectedTaskTitle] 的专注' : '自由番茄专注',
    );

    await _dbHelper.insertSession(session);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
