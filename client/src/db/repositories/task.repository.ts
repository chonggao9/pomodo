// 待办任务与子任务数据访问仓库 (Task & Subtask Repository)
import { SQLiteEngine } from '../engine';
import type { TaskEntity, SubtaskEntity, Priority, Workload, TaskStatus } from '../types';

export class TaskRepository {
  private engine = SQLiteEngine.getInstance();

  /** 获取全部任务列表 */
  public getAllTasks(): TaskEntity[] {
    return this.engine.query<TaskEntity>(`
      SELECT * FROM tasks
      ORDER BY 
        CASE status WHEN 'pending' THEN 0 ELSE 1 END,
        ivy_order ASC,
        created_at DESC;
    `);
  }

  /** 获取待处理艾利任务（按 1~5 顺位排列） */
  public getPendingTasks(): TaskEntity[] {
    return this.engine.query<TaskEntity>(`
      SELECT * FROM tasks
      WHERE status = 'pending'
      ORDER BY ivy_order ASC, created_at DESC;
    `);
  }

  /** 获取已完成任务 */
  public getCompletedTasks(): TaskEntity[] {
    return this.engine.query<TaskEntity>(`
      SELECT * FROM tasks
      WHERE status = 'completed'
      ORDER BY completed_at DESC, updated_at DESC;
    `);
  }

  /** 根据 ID 查询单个任务详情 */
  public getTaskById(id: string): TaskEntity | null {
    return this.engine.queryOne<TaskEntity>('SELECT * FROM tasks WHERE id = ?;', [id]);
  }

  /** 创建新任务 (严格按照艾利工作法 1~5 顺位入列) */
  public createTask(data: {
    title: string;
    notes?: string;
    priority?: Priority;
    workload?: Workload;
    due_date?: string;
    category_id?: string;
  }): TaskEntity {
    const id = `task_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const now = new Date().toISOString();

    // 计算下一个艾利排序位 (1 ~ 5)
    const countRes = this.engine.queryOne<{ count: number }>(
      "SELECT COUNT(*) as count FROM tasks WHERE status = 'pending';"
    );
    const currentPendingCount = countRes ? Number(countRes.count) : 0;
    const ivyOrder = Math.min(5, currentPendingCount + 1);

    const priority = data.priority ?? 'P1';
    const workload = data.workload ?? 'easy';

    this.engine.run(`
      INSERT INTO tasks (id, title, notes, priority, ivy_order, status, workload, due_date, category_id, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?, ?, ?);
    `, [
      id,
      data.title,
      data.notes ?? null,
      priority,
      ivyOrder,
      workload,
      data.due_date ?? null,
      data.category_id ?? 'cat_work',
      now,
      now,
    ]);

    return this.getTaskById(id)!;
  }

  /** 切换任务完成状态 (就地划线变灰或撤销完成) */
  public toggleTaskStatus(id: string): TaskEntity | null {
    const task = this.getTaskById(id);
    if (!task) return null;

    const now = new Date().toISOString();
    const newStatus: TaskStatus = task.status === 'completed' ? 'pending' : 'completed';
    const completedAt = newStatus === 'completed' ? now : null;

    this.engine.run(`
      UPDATE tasks
      SET status = ?, completed_at = ?, updated_at = ?
      WHERE id = ?;
    `, [newStatus, completedAt, now, id]);

    return this.getTaskById(id);
  }

  /** 删除任务 (外键约束将自动级联删除关联的子任务) */
  public deleteTask(id: string): void {
    this.engine.run('DELETE FROM tasks WHERE id = ?;', [id]);
  }

  /** 艾利任务重新排序 (置顶或拖拽重排序) */
  public reorderIvyTasks(orderedIds: string[]): void {
    orderedIds.forEach((id, index) => {
      const order = index + 1;
      this.engine.run('UPDATE tasks SET ivy_order = ?, updated_at = ? WHERE id = ?;', [
        order,
        new Date().toISOString(),
        id,
      ]);
    });
  }

  // ─── 子任务相关 ────────────────────────────────────────────────────────
  
  /** 获取某任务下的全部子任务 */
  public getSubtasks(taskId: string): SubtaskEntity[] {
    return this.engine.query<SubtaskEntity>(`
      SELECT * FROM subtasks
      WHERE task_id = ?
      ORDER BY sort_order ASC, id ASC;
    `, [taskId]);
  }

  /** 创建子任务 */
  public createSubtask(taskId: string, title: string): SubtaskEntity {
    const id = `sub_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`;
    const countRes = this.engine.queryOne<{ count: number }>(
      'SELECT COUNT(*) as count FROM subtasks WHERE task_id = ?;',
      [taskId]
    );
    const sortOrder = countRes ? Number(countRes.count) + 1 : 1;

    this.engine.run(`
      INSERT INTO subtasks (id, task_id, title, is_completed, sort_order)
      VALUES (?, ?, ?, 0, ?);
    `, [id, taskId, title, sortOrder]);

    return {
      id,
      task_id: taskId,
      title,
      is_completed: 0,
      sort_order: sortOrder,
    };
  }

  /** 切换子任务勾选状态 */
  public toggleSubtask(subtaskId: string): boolean {
    const subtask = this.engine.queryOne<SubtaskEntity>('SELECT * FROM subtasks WHERE id = ?;', [subtaskId]);
    if (!subtask) return false;

    const newCompleted = subtask.is_completed === 1 ? 0 : 1;
    this.engine.run('UPDATE subtasks SET is_completed = ? WHERE id = ?;', [newCompleted, subtaskId]);
    return true;
  }
}
