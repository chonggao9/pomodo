import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/task.dart';
import '../../models/pomodoro_session.dart';
import '../../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pomodo_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _configureDB,
    );
  }

  Future<void> _configureDB(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. 版本控制表
    await db.execute('''
      CREATE TABLE schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      )
    ''');

    // 2. 分类表
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT,
        icon TEXT,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    // 3. 任务主表 (对齐 Ivy Lee 1~5 黄金法则)
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        notes TEXT,
        priority TEXT DEFAULT 'P1',
        ivy_order INTEGER DEFAULT 1,
        status TEXT DEFAULT 'pending',
        workload TEXT DEFAULT 'easy',
        due_date TEXT,
        category_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // 4. 子任务表 (级联删除)
    await db.execute('''
      CREATE TABLE subtasks (
        id TEXT PRIMARY KEY,
        task_id TEXT NOT NULL,
        title TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');

    // 5. 番茄专注流水表
    await db.execute('''
      CREATE TABLE pomodoro_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        duration_minutes INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT,
        status TEXT DEFAULT 'completed',
        notes TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE SET NULL
      )
    ''');

    // 记录 migration
    final now = DateTime.now().toIso8601String();
    await db.insert('schema_migrations', {
      'version': 1,
      'applied_at': now,
    });

    // 预植初始种子任务与分类
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('categories', {
      'id': 'cat_work',
      'name': '工作与工程',
      'color': '#008779',
      'icon': 'folder',
      'sort_order': 1,
    });

    await db.insert('categories', {
      'id': 'cat_life',
      'name': '生活与健康',
      'color': '#10B981',
      'icon': 'heart',
      'sort_order': 2,
    });

    // 种子任务 1
    await db.insert('tasks', {
      'id': 'seed_task_1',
      'title': '完成核心架构与 SQLite 本地数据持久化',
      'notes': '100% 离线单机运行，零网络依赖，数据自持安全。',
      'priority': 'P1',
      'ivy_order': 1,
      'status': 'pending',
      'workload': 'hard',
      'due_date': null,
      'category_id': 'cat_work',
      'created_at': now,
      'updated_at': now,
      'completed_at': null,
    });

    // 种子任务 2
    await db.insert('tasks', {
      'id': 'seed_task_2',
      'title': '体验博朗拟物 60 刻度精密机械表盘专注',
      'notes': '感受 Dieter Rams 严谨工业美学与纯粹心流。',
      'priority': 'P1',
      'ivy_order': 2,
      'status': 'pending',
      'workload': 'medium',
      'due_date': null,
      'category_id': 'cat_work',
      'created_at': now,
      'updated_at': now,
      'completed_at': null,
    });

    // 种子任务 3
    await db.insert('tasks', {
      'id': 'seed_task_3',
      'title': '检查离线复盘与个人本地数据中心',
      'notes': '支持 PRAGMA 完整性自检与本地 .db 文件一键导出备份。',
      'priority': 'P2',
      'ivy_order': 3,
      'status': 'pending',
      'workload': 'easy',
      'due_date': null,
      'category_id': 'cat_life',
      'created_at': now,
      'updated_at': now,
      'completed_at': null,
    });
  }

  // === Task CRUD ===
  Future<List<Task>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.query(
      'tasks',
      orderBy: 'CASE WHEN status = "completed" THEN 1 ELSE 0 END ASC, ivy_order ASC, created_at DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> insertTask(Task task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateTask(Task task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Subtasks ===
  Future<List<Subtask>> getSubtasks(String taskId) async {
    final db = await instance.database;
    final result = await db.query(
      'subtasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'sort_order ASC',
    );
    return result.map((json) => Subtask.fromMap(json)).toList();
  }

  Future<int> insertSubtask(Subtask subtask) async {
    final db = await instance.database;
    return await db.insert('subtasks', subtask.toMap());
  }

  Future<int> updateSubtask(Subtask subtask) async {
    final db = await instance.database;
    return await db.update(
      'subtasks',
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> deleteSubtask(String id) async {
    final db = await instance.database;
    return await db.delete(
      'subtasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Pomodoro Sessions ===
  Future<List<PomodoroSession>> getAllSessions() async {
    final db = await instance.database;
    final result = await db.query('pomodoro_sessions', orderBy: 'started_at DESC');
    return result.map((json) => PomodoroSession.fromMap(json)).toList();
  }

  Future<int> insertSession(PomodoroSession session) async {
    final db = await instance.database;
    return await db.insert('pomodoro_sessions', session.toMap());
  }

  // === Categories CRUD ===
  Future<List<Category>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'sort_order ASC, rowid ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await instance.database;
    return await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await instance.database;
    // 将引用该分类的任务 category_id 置为 null
    await db.update(
      'tasks',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, int>> getCategoryTaskCounts() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT category_id, COUNT(*) as count 
      FROM tasks 
      WHERE status != 'completed' AND category_id IS NOT NULL 
      GROUP BY category_id
    ''');
    final Map<String, int> counts = {};
    for (final row in result) {
      final catId = row['category_id'] as String?;
      final cnt = (row['count'] as int?) ?? 0;
      if (catId != null) {
        counts[catId] = cnt;
      }
    }
    return counts;
  }

  // === Database Diagnostics & Maintenance ===
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'pomodo_local.db');
  }

  Future<int> getDatabaseFileSize() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<bool> verifyIntegrity() async {
    final db = await instance.database;
    final result = await db.rawQuery('PRAGMA integrity_check');
    if (result.isNotEmpty && result.first.values.first == 'ok') {
      return true;
    }
    return false;
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await instance.database;
    final totalTasks = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks')) ?? 0;
    final completedTasks = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM tasks WHERE status = "completed"')) ?? 0;
    final totalSessions = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM pomodoro_sessions')) ?? 0;
    final totalFocusMinutes = Sqflite.firstIntValue(await db.rawQuery('SELECT SUM(duration_minutes) FROM pomodoro_sessions WHERE status = "completed"')) ?? 0;

    return {
      'total_tasks': totalTasks,
      'completed_tasks': completedTasks,
      'total_sessions': totalSessions,
      'total_focus_minutes': totalFocusMinutes,
    };
  }

  Future<void> resetDatabase() async {
    final path = await getDatabasePath();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await deleteDatabase(path);
    _database = await _initDB('pomodo_local.db');
  }
}
