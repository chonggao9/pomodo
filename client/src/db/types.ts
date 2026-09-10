// PomoDo 数据模型与 SQLite 实体类型定义

export type Priority = 'P1' | 'P2' | 'P3' | 'P4' | 'P5';
export type TaskStatus = 'pending' | 'completed' | 'archived';
export type Workload = 'easy' | 'medium' | 'hard';
export type PomodoroStatus = 'completed' | 'abandoned';

export interface TaskEntity {
  id: string;
  title: string;
  notes?: string | null;
  priority: Priority;
  ivy_order: number;
  status: TaskStatus;
  workload: Workload;
  due_date?: string | null;
  category_id?: string | null;
  created_at: string;
  updated_at: string;
  completed_at?: string | null;
}

export interface SubtaskEntity {
  id: string;
  task_id: string;
  title: string;
  is_completed: number; // 0 or 1
  sort_order: number;
}

export interface PomodoroSessionEntity {
  id: string;
  task_id?: string | null;
  duration_minutes: number;
  white_noise?: string | null;
  status: PomodoroStatus;
  started_at: string;
  ended_at: string;
}

export interface CategoryEntity {
  id: string;
  name: string;
  color: string;
  icon?: string | null;
  sort_order: number;
}

export interface SchemaMigrationEntity {
  version: number;
  name: string;
  applied_at: string;
}

export interface DatabaseStats {
  totalTasks: number;
  completedTasks: number;
  pendingTasks: number;
  totalPomodoros: number;
  totalFocusMinutes: number;
  todayFocusMinutes: number;
  currentStreakDays: number;
}
