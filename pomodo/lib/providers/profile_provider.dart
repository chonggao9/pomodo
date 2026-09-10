import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';

class ProfileProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String _userName = 'PomoDo 探索者';
  String _motto = '自律带来真正的自由。';
  String _avatarTag = 'astronaut';
  String _appIconTheme = 'light'; // 'light' or 'dark'

  int _fileSizeBytes = 0;
  bool _integrityOk = true;
  String _dbPath = '';
  Map<String, int> _dbStats = {
    'total_tasks': 0,
    'completed_tasks': 0,
    'total_sessions': 0,
    'total_focus_minutes': 0,
  };

  String get userName => _userName;
  String get motto => _motto;
  String get avatarTag => _avatarTag;
  String get appIconTheme => _appIconTheme;
  int get fileSizeBytes => _fileSizeBytes;
  bool get integrityOk => _integrityOk;
  String get dbPath => _dbPath;
  Map<String, int> get dbStats => _dbStats;

  String get formattedFileSize {
    if (_fileSizeBytes < 1024) return '$_fileSizeBytes B';
    if (_fileSizeBytes < 1024 * 1024) {
      return '${(_fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> initProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? 'PomoDo 探索者';
    _motto = prefs.getString('motto') ?? '自律带来真正的自由。';
    _avatarTag = prefs.getString('avatar_tag') ?? 'astronaut';
    _appIconTheme = prefs.getString('app_icon_theme') ?? 'light';

    await refreshDiagnostics();
  }

  Future<void> setAppIconTheme(String theme) async {
    _appIconTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_icon_theme', theme);
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? motto, String? avatarTag}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      _userName = name;
      await prefs.setString('user_name', name);
    }
    if (motto != null) {
      _motto = motto;
      await prefs.setString('motto', motto);
    }
    if (avatarTag != null) {
      _avatarTag = avatarTag;
      await prefs.setString('avatar_tag', avatarTag);
    }
    notifyListeners();
  }

  Future<void> refreshDiagnostics() async {
    try {
      _dbPath = await _dbHelper.getDatabasePath();
      _fileSizeBytes = await _dbHelper.getDatabaseFileSize();
      _integrityOk = await _dbHelper.verifyIntegrity();
      _dbStats = await _dbHelper.getDatabaseStats();
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

      // 安卓常见外部 Download 路径或内部持久路径备份
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
