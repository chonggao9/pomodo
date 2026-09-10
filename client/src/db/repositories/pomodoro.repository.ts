// 番茄专注记录数据仓库 (Pomodoro Repository)
import { SQLiteEngine } from '../engine';
import type { PomodoroSessionEntity, PomodoroStatus } from '../types';

export class PomodoroRepository {
  private engine = SQLiteEngine.getInstance();

  /** 记录一次完整的番茄专注会话 */
  public recordSession(data: {
    task_id?: string | null;
    duration_minutes: number;
    white_noise?: string | null;
    status: PomodoroStatus;
    started_at: string;
    ended_at: string;
  }): PomodoroSessionEntity {
    const id = `pomo_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;

    this.engine.run(`
      INSERT INTO pomodoro_sessions (id, task_id, duration_minutes, white_noise, status, started_at, ended_at)
      VALUES (?, ?, ?, ?, ?, ?, ?);
    `, [
      id,
      data.task_id ?? null,
      data.duration_minutes,
      data.white_noise ?? null,
      data.status,
      data.started_at,
      data.ended_at,
    ]);

    return {
      id,
      task_id: data.task_id ?? null,
      duration_minutes: data.duration_minutes,
      white_noise: data.white_noise ?? null,
      status: data.status,
      started_at: data.started_at,
      ended_at: data.ended_at,
    };
  }

  /** 获取最近的专注记录流水 */
  public getRecentSessions(limit = 20): PomodoroSessionEntity[] {
    return this.engine.query<PomodoroSessionEntity>(`
      SELECT * FROM pomodoro_sessions
      ORDER BY ended_at DESC
      LIMIT ?;
    `, [limit]);
  }

  /** 获取今日专注总分钟数 */
  public getTodayFocusMinutes(): number {
    const todayPrefix = new Date().toISOString().slice(0, 10);
    const res = this.engine.queryOne<{ total: number }>(`
      SELECT SUM(duration_minutes) as total
      FROM pomodoro_sessions
      WHERE status = 'completed' AND started_at LIKE ?;
    `, [`${todayPrefix}%`]);

    return res && res.total ? Number(res.total) : 0;
  }

  /** 获取历史累计有效番茄专注个数 */
  public getTotalCompletedCount(): number {
    const res = this.engine.queryOne<{ count: number }>(`
      SELECT COUNT(*) as count
      FROM pomodoro_sessions
      WHERE status = 'completed';
    `);
    return res ? Number(res.count) : 0;
  }
}
