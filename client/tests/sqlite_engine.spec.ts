import { describe, it, expect, beforeEach } from 'vitest';
import { SQLiteEngine } from '../src/db/engine';
import { TaskRepository } from '../src/db/repositories/task.repository';
import { PomodoroRepository } from '../src/db/repositories/pomodoro.repository';
import { CategoryRepository } from '../src/db/repositories/category.repository';
import { StatsRepository } from '../src/db/repositories/stats.repository';

describe('SQLiteEngine & Migration System', () => {
  let engine: SQLiteEngine;
  let taskRepo: TaskRepository;
  let pomoRepo: PomodoroRepository;
  let catRepo: CategoryRepository;
  let statsRepo: StatsRepository;

  beforeEach(async () => {
    engine = SQLiteEngine.getInstance();
    // 强制使用空二进制重置数据库
    await engine.init();
    taskRepo = new TaskRepository();
    pomoRepo = new PomodoroRepository();
    catRepo = new CategoryRepository();
    statsRepo = new StatsRepository();
  });

  it('should successfully apply schema_migrations and record migration history', () => {
    const applied = engine.getAppliedMigrations();
    expect(applied.length).toBeGreaterThanOrEqual(1);
    expect(applied[0].version).toBe(1);
    expect(applied[0].name).toBe('001_initial_schema');
    expect(applied[0].applied_at).toBeDefined();
  });

  it('should guarantee migration idempotency (running migrations again does nothing)', async () => {
    const rerunCount = await engine.runMigrations();
    expect(rerunCount).toBe(0);
  });

  it('should initialize default categories', () => {
    const categories = catRepo.getAllCategories();
    expect(categories.length).toBeGreaterThanOrEqual(3);
    expect(categories.some(c => c.name === '工作工作')).toBe(true);
    expect(categories.some(c => c.name === '深度学习')).toBe(true);
  });

  it('should create tasks with Ivy Lee 1~5 ordering and toggle completion', () => {
    const task1 = taskRepo.createTask({
      title: '完成 SQLite 引擎架构审查',
      priority: 'P1',
      workload: 'medium',
    });
    expect(task1.id).toBeDefined();
    expect(task1.status).toBe('pending');
    expect(task1.ivy_order).toBe(1);

    const task2 = taskRepo.createTask({
      title: '编写自动化迁移单元测试',
      priority: 'P2',
    });
    expect(task2.ivy_order).toBe(2);

    // 切换状态 -> completed
    const updated = taskRepo.toggleTaskStatus(task1.id);
    expect(updated?.status).toBe('completed');
    expect(updated?.completed_at).toBeDefined();

    // 再次切换 -> pending
    const reverted = taskRepo.toggleTaskStatus(task1.id);
    expect(reverted?.status).toBe('pending');
    expect(reverted?.completed_at).toBeNull();
  });

  it('should support subtasks and cascade delete on task removal', () => {
    const task = taskRepo.createTask({ title: '主任务测试' });
    const sub1 = taskRepo.createSubtask(task.id, '子任务 1');
    const sub2 = taskRepo.createSubtask(task.id, '子任务 2');

    expect(taskRepo.getSubtasks(task.id).length).toBe(2);

    // 切换子任务状态
    taskRepo.toggleSubtask(sub1.id);
    const subtasks = taskRepo.getSubtasks(task.id);
    expect(subtasks.find(s => s.id === sub1.id)?.is_completed).toBe(1);

    // 删除主任务，验证外键级联删除
    taskRepo.deleteTask(task.id);
    expect(taskRepo.getSubtasks(task.id).length).toBe(0);
  });

  it('should record Pomodoro focus sessions and compute aggregated statistics', () => {
    const now = new Date().toISOString();
    pomoRepo.recordSession({
      duration_minutes: 25,
      white_noise: '雨声',
      status: 'completed',
      started_at: now,
      ended_at: now,
    });

    const todayMins = pomoRepo.getTodayFocusMinutes();
    expect(todayMins).toBeGreaterThanOrEqual(25);

    const stats = statsRepo.getOverviewStats();
    expect(stats.totalPomodoros).toBeGreaterThanOrEqual(1);
    expect(stats.totalFocusMinutes).toBeGreaterThanOrEqual(25);
  });

  it('should export standard SQLite 3 binary file and re-import correctly', async () => {
    // 写入一个特征任务
    taskRepo.createTask({ title: '用于二进制备份验证的特定待办' });

    // 导出物理二进制
    const binary = engine.exportBinary();
    expect(binary).toBeInstanceOf(Uint8Array);
    expect(binary.length).toBeGreaterThan(0);

    // 验证标准 SQLite 头部魔数 "SQLite format 3\0"
    const header = new TextDecoder().decode(binary.slice(0, 16));
    expect(header.startsWith('SQLite format 3')).toBe(true);

    // 重新导入二进制到引擎
    await engine.importBinary(binary);

    // 验证特征任务仍完整存在
    const tasks = taskRepo.getAllTasks();
    expect(tasks.some(t => t.title === '用于二进制备份验证的特定待办')).toBe(true);
  });

  it('should accurately calculate database metrics and allow clean wiping', async () => {
    // 1. 获取指标
    const metricsBefore = engine.getDatabaseMetrics();
    expect(metricsBefore.fileSizeBytes).toBeGreaterThan(0);
    expect(metricsBefore.taskCount).toBeGreaterThan(0);
    expect(metricsBefore.integrityStatus).toBe('ok');
    expect(metricsBefore.schemaVersion).toBe(1);

    // 2. 执行清空
    await engine.wipeAndResetDatabase();

    // 3. 验证数据已归零且库完好
    const metricsAfter = engine.getDatabaseMetrics();
    expect(metricsAfter.taskCount).toBe(0);
    expect(metricsAfter.sessionCount).toBe(0);
    expect(metricsAfter.integrityStatus).toBe('ok');
  });
});

