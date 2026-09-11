import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pomodo/core/i18n/app_strings.dart';
import 'package:pomodo/models/task.dart';
import 'package:pomodo/providers/locale_provider.dart';
import 'package:pomodo/providers/pomodoro_provider.dart';
import 'package:pomodo/providers/task_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocaleProvider Tests', () {
    test('Default system locale falls back correctly', () async {
      final prov = LocaleProvider();
      await prov.initLocale();
      expect(prov.language, AppLanguage.system);
    });

    test('Switch language to zh and en', () async {
      final prov = LocaleProvider();
      await prov.setLanguage(AppLanguage.zh);
      expect(prov.language, AppLanguage.zh);
      expect(prov.currentLocale.languageCode, 'zh');
      expect(prov.isZh, true);

      await prov.setLanguage(AppLanguage.en);
      expect(prov.language, AppLanguage.en);
      expect(prov.currentLocale.languageCode, 'en');
      expect(prov.isZh, false);
    });
  });

  group('PomodoroProvider Preset Tests', () {
    test('Preset focus minutes and break minutes', () {
      final pomo = PomodoroProvider();
      expect(pomo.presetMinutes, contains(25));
      expect(pomo.presetMinutes, contains(60));
      expect(pomo.presetBreakMinutes, contains(5));
      expect(pomo.presetBreakMinutes, contains(10));
      expect(pomo.presetBreakMinutes, contains(15));
      expect(pomo.targetMinutes, 25);
      expect(pomo.breakMinutes, 5);

      pomo.setTargetMinutes(35);
      expect(pomo.targetMinutes, 35);

      pomo.setBreakMinutes(10);
      expect(pomo.breakMinutes, 10);

      expect(pomo.soundPresets, contains('🌧️ 窗台夜雨'));
      expect(pomo.soundPresets, contains('🌊 深海潮汐'));
      expect(pomo.soundPresets, contains('🌲 夜色篝火'));
      expect(pomo.soundPresets, contains('🔇 静音模式'));
    });
  });

  group('TaskProvider Category Selection Tests', () {
    test('selectCategory toggles and clears correctly', () {
      final taskProv = TaskProvider();
      expect(taskProv.selectedCategoryId, isNull);

      taskProv.selectCategory('cat-1');
      expect(taskProv.selectedCategoryId, 'cat-1');

      // Clicking same category toggles off
      taskProv.selectCategory('cat-1');
      expect(taskProv.selectedCategoryId, isNull);

      // Selecting another category sets it
      taskProv.selectCategory('cat-2');
      expect(taskProv.selectedCategoryId, 'cat-2');

      // getTaskPomoSummary returns null for unknown task
      expect(taskProv.getTaskPomoSummary('non-existent'), isNull);
    });
  });

  group('PomodoroProvider Mode and Binding Tests', () {
    test('Task binding and unbinding', () {
      final pomo = PomodoroProvider();
      expect(pomo.selectedTaskId, isNull);
      expect(pomo.selectedTaskTitle, isNull);

      pomo.selectTask('task-101', '设计新方案');
      expect(pomo.selectedTaskId, 'task-101');
      expect(pomo.selectedTaskTitle, '设计新方案');

      pomo.unbindTask();
      expect(pomo.selectedTaskId, isNull);
      expect(pomo.selectedTaskTitle, isNull);
    });

    test('Short break mode switching and reset', () {
      final pomo = PomodoroProvider();
      expect(pomo.isRestMode, false);
      expect(pomo.mode, PomodoroMode.focus);

      pomo.startRest(5);
      expect(pomo.isRestMode, true);
      expect(pomo.mode, PomodoroMode.rest);
      expect(pomo.isRunning, true);
      expect(pomo.remainingSeconds, 5 * 60);

      pomo.reset();
      expect(pomo.isRestMode, false);
      expect(pomo.mode, PomodoroMode.focus);
      expect(pomo.state, PomodoroState.idle);
      expect(pomo.remainingSeconds, pomo.targetMinutes * 60);
    });
  });

  group('Things 3 Dual-Track (Inbox & Today) Workflow Tests', () {
    test('Task copyWith clearDueDate and clearCompletedAt', () {
      final task = Task(
        id: 't-1',
        title: '测试事项',
        createdAt: '2026-09-11T10:00:00',
        updatedAt: '2026-09-11T10:00:00',
        dueDate: '2026-09-11',
        completedAt: '2026-09-11T10:30:00',
      );

      final cleared = task.copyWith(clearDueDate: true, clearCompletedAt: true);
      expect(cleared.dueDate, isNull);
      expect(cleared.completedAt, isNull);
      expect(cleared.title, '测试事项');
    });

    test('Inbox separates unassigned tasks from Today tasks', () {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final taskProv = TaskProvider();
      final inboxTask1 = Task(
        id: 'inbox-1',
        title: '收集箱灵感1',
        dueDate: null,
        status: 'pending',
        createdAt: '2026-09-11T09:00:00',
        updatedAt: '2026-09-11T09:00:00',
      );
      final inboxTask2 = Task(
        id: 'inbox-2',
        title: '收集箱灵感2',
        dueDate: null,
        status: 'pending',
        createdAt: '2026-09-11T09:10:00',
        updatedAt: '2026-09-11T09:10:00',
      );
      final inboxCompleted = Task(
        id: 'inbox-done',
        title: '收集箱已完成',
        dueDate: null,
        status: 'completed',
        createdAt: '2026-09-11T08:00:00',
        updatedAt: '2026-09-11T08:00:00',
      );
      final todayTask = Task(
        id: 'today-1',
        title: '今日要务',
        dueDate: todayStr,
        status: 'pending',
        createdAt: '2026-09-11T09:20:00',
        updatedAt: '2026-09-11T09:20:00',
      );
      final pastOverdueTask = Task(
        id: 'overdue-1',
        title: '昨日遗留任务',
        dueDate: '2026-09-01',
        status: 'pending',
        createdAt: '2026-09-01T09:00:00',
        updatedAt: '2026-09-01T09:00:00',
      );

      taskProv.setTasksForTesting([
        inboxTask1,
        inboxTask2,
        inboxCompleted,
        todayTask,
        pastOverdueTask,
      ]);

      // 1. 收集箱只包含 dueDate == null 且未完成的任务
      expect(taskProv.inboxCount, 2);
      expect(taskProv.inboxTasks.map((t) => t.id), containsAll(['inbox-1', 'inbox-2']));
      expect(taskProv.inboxTasks.any((t) => t.id == 'inbox-done'), false);

      // 2. 今日列表只包含今日截止任务与历史顺延任务，严禁包含 dueDate == null 的收集箱任务
      final todayList = taskProv.tasksForDate(now);
      expect(todayList.map((t) => t.id), containsAll(['today-1', 'overdue-1']));
      expect(todayList.any((t) => t.id == 'inbox-1'), false);
      expect(todayList.any((t) => t.id == 'inbox-2'), false);
      expect(todayList.any((t) => t.id == 'inbox-done'), false);
    });

    test('Localization strings for Inbox & All-Done exist in both languages', () {
      final zh = AppStrings(const Locale('zh', 'CN'));
      final en = AppStrings(const Locale('en', 'US'));

      expect(zh.inboxTitle, '收集箱');
      expect(zh.moveToToday, '安排到今天');
      expect(zh.allTasksDoneTitle, '今日要务已全部达成！🎉');
      expect(zh.todayAllDoneText, '今日全部搞定');

      expect(en.inboxTitle, 'Inbox');
      expect(en.moveToToday, 'Move to Today');
      expect(en.allTasksDoneTitle, 'All Done for Today! 🎉');
      expect(en.todayAllDoneText, 'All Accomplished');
    });
  });

  group('Logbook & Stats Revamp Tests', () {
    test('allCompletedTasks sorts completed tasks by completion date descending', () {
      final taskProv = TaskProvider();
      final task1 = Task(
        id: 'c-1',
        title: '早期完成任务',
        status: 'completed',
        completedAt: '2026-09-10T10:00:00',
        createdAt: '2026-09-10T08:00:00',
        updatedAt: '2026-09-10T10:00:00',
      );
      final task2 = Task(
        id: 'c-2',
        title: '最新完成任务',
        status: 'completed',
        completedAt: '2026-09-11T12:00:00',
        createdAt: '2026-09-11T08:00:00',
        updatedAt: '2026-09-11T12:00:00',
      );
      final pendingTask = Task(
        id: 'p-1',
        title: '未完成任务',
        status: 'pending',
        createdAt: '2026-09-11T08:00:00',
        updatedAt: '2026-09-11T08:00:00',
      );

      taskProv.setTasksForTesting([task1, task2, pendingTask]);

      expect(taskProv.allCompletedTasks.length, 2);
      // 最新完成排在最前
      expect(taskProv.allCompletedTasks.first.id, 'c-2');
      expect(taskProv.allCompletedTasks.last.id, 'c-1');
      expect(taskProv.allCompletedTasks.any((t) => t.id == 'p-1'), false);
    });

    test('Logbook & Stats Revamp localization strings exist in zh & en', () {
      final zh = AppStrings(const Locale('zh', 'CN'));
      final en = AppStrings(const Locale('en', 'US'));

      expect(zh.logbookTitle, '历史达成归档');
      expect(zh.dualRingsTitle, '效能闭环');
      expect(zh.categoryTimeDist, '时间投资分布');
      expect(zh.dimensionToday, '今日');
      expect(zh.dimensionWeek, '本周');

      expect(en.logbookTitle, 'Logbook Archive');
      expect(en.dualRingsTitle, 'Activity Rings');
      expect(en.categoryTimeDist, 'Time by Category');
      expect(en.dimensionToday, 'Today');
      expect(en.dimensionWeek, 'This Week');
    });
  });

  group('Bilateral Task-Pomodoro Lifecycle & Risk Defense Tests', () {
    test('onTaskDeleted while running preserves focus flow and unbinds task', () {
      final pomo = PomodoroProvider();
      pomo.setSelectedSound('🔇 静音模式');
      pomo.selectTask('task-999', '正在攻克的硬核任务');
      pomo.start();

      expect(pomo.isRunning, true);
      expect(pomo.selectedTaskId, 'task-999');

      // 模拟任务被删除
      pomo.onTaskDeleted('task-999');

      // 验证：倒计时绝不被粗暴掐断（心流保护），但解绑任务转为自由专注
      expect(pomo.isRunning, true);
      expect(pomo.selectedTaskId, isNull);
      expect(pomo.selectedTaskTitle, isNull);

      pomo.reset();
    });

    test('onTaskDeleted while idle immediately unbinds', () {
      final pomo = PomodoroProvider();
      pomo.setSelectedSound('🔇 静音模式');
      pomo.selectTask('task-888', '待命任务');
      expect(pomo.selectedTaskId, 'task-888');

      pomo.onTaskDeleted('task-888');
      expect(pomo.selectedTaskId, isNull);
      expect(pomo.selectedTaskTitle, isNull);
    });

    test('onTaskCompleted while running auto-settles and unbinds', () async {
      final pomo = PomodoroProvider();
      pomo.setSelectedSound('🔇 静音模式');
      pomo.selectTask('task-777', '进行中的任务');
      pomo.start();

      expect(pomo.isRunning, true);

      // 若专注时间小于 60 秒（防抖拦截），返回 0 分钟且不产生脏数据
      final settledMinutes = await pomo.onTaskCompleted('task-777');
      expect(settledMinutes, 0); // 刚启动不足 60 秒，被防抖保护拦截
      expect(pomo.selectedTaskId, isNull);
      expect(pomo.isRunning, false);
    });

    test('Bilateral conflict & settlement strings exist in zh & en', () {
      final zh = AppStrings(const Locale('zh', 'CN'));
      final en = AppStrings(const Locale('en', 'US'));

      expect(zh.sessionTooShort, contains('不足 1 分钟'));
      expect(zh.taskCompletedAutoSettle, contains('自动结算'));
      expect(zh.focusConflictTitle, '正在专注其他任务');
      expect(zh.settleAndSwitch, '结算并切换');
      expect(zh.discardAndSwitch, '放弃并切换');

      expect(en.sessionTooShort, contains('under 1 min'));
      expect(en.taskCompletedAutoSettle, contains('auto-settled'));
      expect(en.focusConflictTitle, 'Another Focus in Progress');
      expect(en.settleAndSwitch, 'Settle & Switch');
      expect(en.discardAndSwitch, 'Discard & Switch');
    });
  });
}
