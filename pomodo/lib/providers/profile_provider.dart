import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';

class ProfileProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _userName = 'Vy';
  String _motto = '艾利 Lee 黄金法则 · 每日聚焦最核心要务';
  String _avatarTag = 'sunset';
  String _gender = 'male'; // 'male', 'female', 'secret'
  String _appIconTheme = 'light'; // 'light' or 'dark'
  ThemeMode _themeMode = ThemeMode.light; // ThemeMode.light, ThemeMode.dark, ThemeMode.system

  // 待办与清单偏好设置
  int _dailyTaskLimit = 5; // 3, 5, 6, 0 (不限)
  String _completionBehavior = 'keep_in_place'; // 'keep_in_place', 'move_to_bottom', 'hide'
  bool _autoRollover = true;

  int _fileSizeBytes = 0;
  bool _integrityOk = true;
  String _dbPath = '';
  Map<String, int> _dbStats = {
    'total_tasks': 0,
    'completed_tasks': 0,
    'total_sessions': 0,
    'total_focus_minutes': 0,
  };

  Map<String, dynamic> _badgeAchievements = {
    'time_master': {'unlocked': false, 'current': 0, 'target': 7},
    'focus_king': {'unlocked': false, 'current': 0, 'target': 3000},
    'pomo_tycoon': {'unlocked': false, 'current': 0, 'target': 8},
    'night_owl': {'unlocked': false, 'current': 0, 'target': 1},
  };

  String get userName => _userName;
  String get motto => _motto;
  String get avatarTag => _avatarTag;
  String get gender => _gender;
  String get appIconTheme => _appIconTheme;
  ThemeMode get themeMode => _themeMode;

  int get dailyTaskLimit => _dailyTaskLimit;
  String get completionBehavior => _completionBehavior;
  bool get autoRollover => _autoRollover;

  int get fileSizeBytes => _fileSizeBytes;
  bool get integrityOk => _integrityOk;
  String get dbPath => _dbPath;
  Map<String, int> get dbStats => _dbStats;
  Map<String, dynamic> get badgeAchievements => _badgeAchievements;

  String get formattedFileSize {
    if (_fileSizeBytes < 1024) return '$_fileSizeBytes B';
    if (_fileSizeBytes < 1024 * 1024) {
      return '${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> initProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'Vy';
    _motto = prefs.getString('motto') ?? '艾利 Lee 黄金法则 · 每日聚焦最核心要务';
    _avatarTag = prefs.getString('avatar_tag') ?? 'sunset';
    _gender = prefs.getString('gender') ?? 'male';
    _appIconTheme = prefs.getString('app_icon_theme') ?? 'light';

    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (savedTheme == 'system') {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.light;
    }

    _dailyTaskLimit = prefs.getInt('daily_task_limit') ?? 5;
    _completionBehavior = prefs.getString('completion_behavior') ?? 'keep_in_place';
    _autoRollover = prefs.getBool('auto_rollover') ?? true;

    await refreshDiagnostics();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    String val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.system) val = 'system';
    await prefs.setString('theme_mode', val);
    notifyListeners();
  }

  Future<void> setAppIconTheme(String theme) async {
    _appIconTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_icon_theme', theme);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? motto, String? gender, String? avatarTag}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) {
      _userName = name;
      await prefs.setString('user_name', name);
    }
    if (motto != null) {
      _motto = motto;
      await prefs.setString('motto', motto);
    }
    if (gender != null) {
      _gender = gender;
      await prefs.setString('gender', gender);
    }
    if (avatarTag != null) {
      _avatarTag = avatarTag;
      await prefs.setString('avatar_tag', avatarTag);
    }
    notifyListeners();
  }

  Future<void> setDailyTaskLimit(int limit) async {
    _dailyTaskLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_task_limit', limit);
    notifyListeners();
  }

  Future<void> setCompletionBehavior(String behavior) async {
    _completionBehavior = behavior;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('completion_behavior', behavior);
    notifyListeners();
  }

  Future<void> setAutoRollover(bool val) async {
    _autoRollover = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_rollover', val);
    notifyListeners();
  }

  Future<void> refreshDiagnostics() async {
    try {
      _dbPath = await _dbHelper.getDatabasePath();
      _fileSizeBytes = await _dbHelper.getDatabaseFileSize();
      _integrityOk = await _dbHelper.verifyIntegrity();
      _dbStats = await _dbHelper.getDatabaseStats();
      _badgeAchievements = await _dbHelper.getBadgeAchievements();
    } catch (e) {
      debugPrint('Error diagnostics: $e');
    }
    notifyListeners();
  }

  Future<String?> exportDatabaseToDownload() async {
    try {
      final srcPath = await _dbHelper.getDatabasePath();
      final srcFile = File(srcPath);
      if (!await srcFile.exists()) return null;

      final exportDir = Directory('/storage/emulated/0/Download');
      final exportPath = (await exportDir.exists())
          ? '/storage/emulated/0/Download/pomodo_backup_${DateTime.now().millisecondsSinceEpoch}.db'
          : '${srcFile.parent.path}/pomodo_backup_${DateTime.now().millisecondsSinceEpoch}.db';

      await srcFile.copy(exportPath);
      return exportPath;
    } catch (e) {
      debugPrint('Export failed: $e');
      return null;
    }
  }

  Future<void> resetAllData() async {
    await _dbHelper.resetDatabase();
    await refreshDiagnostics();
  }
}
