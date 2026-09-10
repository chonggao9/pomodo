// GTD 统计分析数据仓库 (Stats Repository)
import { SQLiteEngine } from '../engine';
import type { DatabaseStats } from '../types';

export class StatsRepository {
  private engine = SQLiteEngine.getInstance();

  /** 获取整体统计看板数据 */
  public getOverviewStats(): DatabaseStats {
    const taskStats = this.engine.queryOne<{ total: number; completed: number; pending: number }>(`
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending
      FROM tasks;
    `);

    const pomoStats = this.engine.queryOne<{ total_count: number; total_minutes: number }>(`
      SELECT 
        COUNT(*) as total_count,
        SUM(duration_minutes) as total_minutes
      FROM pomodoro_sessions
      WHERE status = 'completed';
    `);

    const todayPrefix = new Date().toISOString().slice(0, 10);
    const todayPomo = this.engine.queryOne<{ today_minutes: number }>(`
      SELECT SUM(duration_minutes) as today_minutes
      FROM pomodoro_sessions
      WHERE status = 'completed' AND started_at LIKE ?;
    `, [`${todayPrefix}%`]);

    return {
      totalTasks: taskStats ? Number(taskStats.total || 0) : 0,
      completedTasks: taskStats ? Number(taskStats.completed || 0) : 0,
      pendingTasks: taskStats ? Number(taskStats.pending || 0) : 0,
      totalPomodoros: pomoStats ? Number(pomoStats.total_count || 0) : 0,
      totalFocusMinutes: pomoStats ? Number(pomoStats.total_minutes || 0) : 0,
      todayFocusMinutes: todayPomo ? Number(todayPomo.today_minutes || 0) : 0,
      currentStreakDays: 1, // 可按天聚合连续记录
    };
  }
}
