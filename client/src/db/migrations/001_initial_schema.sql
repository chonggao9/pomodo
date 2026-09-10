-- Migration 001: Initial Schema for PomoDo
-- 1. 版本迁移控制表
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  applied_at DATETIME NOT NULL
);

-- 2. 待办任务表
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  notes TEXT,
  priority TEXT CHECK(priority IN ('P1','P2','P3','P4','P5')) DEFAULT 'P1',
  ivy_order INTEGER DEFAULT 1,
  status TEXT CHECK(status IN ('pending','completed','archived')) DEFAULT 'pending',
  workload TEXT CHECK(workload IN ('easy','medium','hard')) DEFAULT 'easy',
  due_date TEXT,
  category_id TEXT,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  completed_at DATETIME
);

-- 3. 子任务表
CREATE TABLE IF NOT EXISTS subtasks (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  title TEXT NOT NULL,
  is_completed INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- 4. 番茄专注记录表
CREATE TABLE IF NOT EXISTS pomodoro_sessions (
  id TEXT PRIMARY KEY,
  task_id TEXT,
  duration_minutes INTEGER NOT NULL DEFAULT 25,
  white_noise TEXT,
  status TEXT CHECK(status IN ('completed','abandoned')) DEFAULT 'completed',
  started_at DATETIME NOT NULL,
  ended_at DATETIME NOT NULL,
  FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
);

-- 5. 分类清单表
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  icon TEXT,
  sort_order INTEGER DEFAULT 0
);

-- 默认内置分类与初始艾利任务
INSERT OR IGNORE INTO categories (id, name, color, icon, sort_order) VALUES
  ('cat_work', '工作工作', '#008779', 'briefcase', 1),
  ('cat_study', '深度学习', '#2980B9', 'book', 2),
  ('cat_life', '日常生活', '#E67E22', 'coffee', 3);
