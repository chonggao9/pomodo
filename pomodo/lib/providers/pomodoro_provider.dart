import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../core/services/white_noise_service.dart';
import '../models/pomodoro_session.dart';

enum PomodoroState { idle, running, paused, completed }
enum PomodoroMode { focus, rest }

class PomodoroProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  int _targetMinutes = 25;
  int _breakMinutes = 5;
  int _remainingSeconds = 25 * 60;
  Timer? _timer;
  PomodoroState _state = PomodoroState.idle;
  PomodoroMode _mode = PomodoroMode.focus;
  bool _showCompletionPrompt = false;

  String? _selectedTaskId;
  String? _selectedTaskTitle;
  DateTime? _sessionStartTime;
  DateTime? _targetEndTime;
  String _selectedSound = '🌧️ 窗台夜雨'; // 默认开启真实自然窗台夜雨
  bool _isPreviewPlaying = false;

  final List<int> _presetMinutes = [15, 25, 35, 45, 60];
  final List<int> _presetBreakMinutes = [5, 10, 15];
  final List<String> _soundPresets = ['🌧️ 窗台夜雨', '🌊 深海潮汐', '🌲 夜色篝火', '🔇 静音模式'];

  int get targetMinutes => _targetMinutes;
  int get breakMinutes => _breakMinutes;
  int get remainingSeconds => _remainingSeconds;
  PomodoroState get state => _state;
  PomodoroMode get mode => _mode;
  bool get isRestMode => _mode == PomodoroMode.rest;
  bool get isRunning => _state == PomodoroState.running;
  bool get isPaused => _state == PomodoroState.paused;
  bool get showCompletionPrompt => _showCompletionPrompt;
  String? get selectedTaskId => _selectedTaskId;
  String? get selectedTaskTitle => _selectedTaskTitle;
  String get selectedSound => _selectedSound;
  bool get isPreviewPlaying => _isPreviewPlaying;
  List<int> get presetMinutes => _presetMinutes;
  List<int> get presetBreakMinutes => _presetBreakMinutes;
  List<String> get soundPresets => _soundPresets;

  double get progress {
    final totalSeconds =
        _mode == PomodoroMode.rest ? (_breakMinutes * 60) : (_targetMinutes * 60);
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

  void dismissCompletionPrompt() {
    _showCompletionPrompt = false;
    notifyListeners();
  }

  Future<void> initPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _targetMinutes = prefs.getInt('pomodoro_target_minutes') ?? 25;
    _breakMinutes = prefs.getInt('pomodoro_break_minutes') ?? 5;
    _selectedSound = prefs.getString('pomodoro_sound') ?? '🌧️ 窗台夜雨';
    if (_state == PomodoroState.idle) {
      _remainingSeconds = _targetMinutes * 60;
    }
    notifyListeners();
  }

  void setTargetMinutes(int minutes) {
    if (_state == PomodoroState.running) return;
    _targetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _state = PomodoroState.idle;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('pomodoro_target_minutes', minutes));
    notifyListeners();
  }

  void setBreakMinutes(int minutes) {
    _breakMinutes = minutes;
    SharedPreferences.getInstance().then((prefs) => prefs.setInt('pomodoro_break_minutes', minutes));
    notifyListeners();
  }

  void setSelectedSound(String sound) {
    _selectedSound = sound;
    SharedPreferences.getInstance().then((prefs) => prefs.setString('pomodoro_sound', sound));
    if (_state == PomodoroState.running) {
      _playCurrentSound();
    } else if (_isPreviewPlaying) {
      if (sound == '静音模式') {
        _stopSound();
      } else {
        WhiteNoiseService.instance.play(_selectedSound);
      }
    }
    notifyListeners();
  }

  void toggleSoundPreview() {
    if (_state == PomodoroState.running) return; // 正在专注运行时无需手动试听

    if (_isPreviewPlaying) {
      _stopSound();
    } else {
      if (_selectedSound != '静音模式') {
        _isPreviewPlaying = true;
        WhiteNoiseService.instance.play(_selectedSound);
      }
    }
    notifyListeners();
  }

  void selectTask(String? id, String? title) {
    _selectedTaskId = id;
    _selectedTaskTitle = title;
    notifyListeners();
  }

  void unbindTask() {
    _selectedTaskId = null;
    _selectedTaskTitle = null;
    notifyListeners();
  }

  void start() {
    if (_state == PomodoroState.running) return;

    _mode = PomodoroMode.focus;
    _showCompletionPrompt = false;

    if (_state == PomodoroState.idle || _state == PomodoroState.completed) {
      _remainingSeconds = _targetMinutes * 60;
      _sessionStartTime = DateTime.now();
    }

    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _state = PomodoroState.running;
    _isPreviewPlaying = false;
    _playCurrentSound();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_targetEndTime != null && now.isBefore(_targetEndTime!)) {
        _remainingSeconds = _targetEndTime!.difference(now).inSeconds;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        _finishSession();
      }
    });
    notifyListeners();
  }

  /// 开启短休倒计时
  void startRest([int? minutes]) {
    _timer?.cancel();
    _stopSound();
    _mode = PomodoroMode.rest;
    _showCompletionPrompt = false;
    final restMins = minutes ?? _breakMinutes;
    _remainingSeconds = restMins * 60;
    _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));
    _state = PomodoroState.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_targetEndTime != null && now.isBefore(_targetEndTime!)) {
        _remainingSeconds = _targetEndTime!.difference(now).inSeconds;
        notifyListeners();
      } else {
        _remainingSeconds = 0;
        _finishRestSession();
      }
    });
    notifyListeners();
  }

  void _finishRestSession() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _mode = PomodoroMode.focus;
    _remainingSeconds = _targetMinutes * 60;
    _targetEndTime = null;
    notifyListeners();
  }

  void pause() {
    if (_state != PomodoroState.running) return;
    _timer?.cancel();
    if (_targetEndTime != null) {
      final now = DateTime.now();
      final totalSeconds = _mode == PomodoroMode.rest ? (_breakMinutes * 60) : (_targetMinutes * 60);
      _remainingSeconds = _targetEndTime!.difference(now).inSeconds.clamp(0, totalSeconds);
    }
    _targetEndTime = null;
    _state = PomodoroState.paused;
    WhiteNoiseService.instance.pause();
    notifyListeners();
  }

  void resume() {
    if (_state == PomodoroState.paused) {
      _state = PomodoroState.running;
      if (_mode == PomodoroMode.focus) {
        WhiteNoiseService.instance.resume();
      }
      _targetEndTime = DateTime.now().add(Duration(seconds: _remainingSeconds));

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        if (_targetEndTime != null && now.isBefore(_targetEndTime!)) {
          _remainingSeconds = _targetEndTime!.difference(now).inSeconds;
          notifyListeners();
        } else {
          _remainingSeconds = 0;
          if (_mode == PomodoroMode.rest) {
            _finishRestSession();
          } else {
            _finishSession();
          }
        }
      });
      notifyListeners();
    } else {
      if (_mode == PomodoroMode.rest) {
        startRest();
      } else {
        start();
      }
    }
  }

  void reset() {
    _timer?.cancel();
    _mode = PomodoroMode.focus;
    _remainingSeconds = _targetMinutes * 60;
    _state = PomodoroState.idle;
    _showCompletionPrompt = false;
    _sessionStartTime = null;
    _targetEndTime = null;
    _stopSound();
    notifyListeners();
  }

  void _playCurrentSound() {
    if (_selectedSound == '静音模式') {
      WhiteNoiseService.instance.stop();
    } else {
      WhiteNoiseService.instance.play(_selectedSound);
    }
  }

  void _stopSound() {
    _isPreviewPlaying = false;
    WhiteNoiseService.instance.stop();
  }

  Future<void> _finishSession() async {
    _timer?.cancel();
    _state = PomodoroState.completed;
    _stopSound();

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
    _showCompletionPrompt = true;
    _remainingSeconds = _targetMinutes * 60;
    _targetEndTime = null;
    notifyListeners();
  }

  /// 提前完成并结算当前专注，停止白噪音并记录到 SQLite
  /// 返回实际结算的专注分钟数（若小于 60 秒微时段则直接重置并返回 0，杜绝垃圾数据污染）
  Future<int> completeEarly() async {
    _timer?.cancel();
    _stopSound();

    final now = DateTime.now();
    final totalPlannedSeconds = _targetMinutes * 60;
    final elapsedSeconds = totalPlannedSeconds - _remainingSeconds;

    // 微时段垃圾数据防抖（不足 60 秒不产生脏流水）
    if (elapsedSeconds < 60) {
      _state = PomodoroState.idle;
      _remainingSeconds = _targetMinutes * 60;
      _sessionStartTime = null;
      _targetEndTime = null;
      notifyListeners();
      return 0;
    }

    int actualMinutes = (elapsedSeconds / 60).ceil();
    if (actualMinutes < 1) actualMinutes = 1;
    if (actualMinutes > _targetMinutes) actualMinutes = _targetMinutes;

    final session = PomodoroSession(
      id: 'pomo_${now.millisecondsSinceEpoch}',
      taskId: _selectedTaskId,
      durationMinutes: actualMinutes,
      startedAt: _sessionStartTime?.toIso8601String() ?? now.toIso8601String(),
      endedAt: now.toIso8601String(),
      status: 'completed',
      notes: _selectedTaskTitle != null ? '提前达成专注 [$_selectedTaskTitle]' : '提前达成专注',
    );

    await _dbHelper.insertSession(session);

    _state = PomodoroState.idle;
    _remainingSeconds = _targetMinutes * 60;
    _sessionStartTime = null;
    _targetEndTime = null;
    notifyListeners();

    return actualMinutes;
  }

  // === 双向生命周期联合处理机制 ===

  /// 规则 1：任务被删除时的联动处理（心流保护原则）
  void onTaskDeleted(String deletedTaskId) {
    if (_selectedTaskId == deletedTaskId) {
      if (isRunning) {
        // 正在倒计时中：保护当前心流，无缝降级为自由专注
        _selectedTaskId = null;
        _selectedTaskTitle = null;
        notifyListeners();
      } else {
        // 待命或暂停中：直接解绑
        unbindTask();
      }
    }
  }

  /// 规则 2：任务在待办页被打勾完成时的联动处理
  Future<int> onTaskCompleted(String completedTaskId) async {
    if (_selectedTaskId == completedTaskId) {
      if (isRunning) {
        // 正在计时：自动结算已专注时长入库并解绑
        final actual = await completeEarly();
        unbindTask();
        return actual;
      } else {
        // 待命或暂停中：直接解绑
        unbindTask();
        return 0;
      }
    }
    return 0;
  }

  /// 规则 3：专注冲突切换（正在专注任务 A 时点击任务 B 开始专注）
  Future<void> switchTaskAndRestart(String newTaskId, String newTitle, {bool saveCurrent = true}) async {
    if (saveCurrent && isRunning) {
      await completeEarly();
    } else {
      reset();
    }
    selectTask(newTaskId, newTitle);
    start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WhiteNoiseService.instance.stop();
    super.dispose();
  }
}
