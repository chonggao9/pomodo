# PomoDo (Pomodoro × ToDo 极简时间管理)

> 一款专注高效的极简时间管理应用（融合 Pomodoro 番茄钟 + 艾利工作法 ToDo 待办清单）  
> 视觉语言：正统官方「马尔斯绿 (`#008779`)」雅致纯白底 · Emil Kowalski 动效工艺  
> 数据存储：**SQLite 本地嵌入式数据库 · Schema 自动化迁移引擎 · 拒绝易损的 JSON 文件存储**

---

## 一、V1 核心原则与产品边界

1. **第一版完全不做后端、不做用户系统**：
   - 零网络依赖、离线即用、绝对保护用户数据隐私。
   - **底层数据存储：标准 SQLite 3 嵌入式数据库**（移动端/桌面端原生 `.db` 文件，Web 端基于 `SQLite WASM / OPFS`）。
   - **内置 Schema Migration 版本迁移表**（`schema_migrations`），解决纯 JSON 结构变更容易损坏旧数据、难以平滑升级和迁移的致命弊端。
   - 支持一键导出、导入标准 `.db` 物理数据库文件，随时可供通用数据库工具查验与无损跨端迁移。
2. **核心功能严格收敛为 4 个 Tab**：
   - **清单**：艾利时间管理法 1~5 排序、周历起伏波浪线、钢笔墨水 Clip-Path 就地划线消灭待办。
   - **专注**：经典拟物机械 60 格分针刻度白表盘、等宽无抖动大号倒计时、离线白噪音。
   - **复盘**：GTD 模块化数据报表、双色核心指标卡、平滑面积趋势图、完成率圆环。
   - **我的**：本地成就勋章、多彩主题随心换（即刻全站换色）、本地 SQLite 数据库运维与迁移。
3. **关键交互与动效标准（锁定）**：
   - **新建任务形态**：**方案 C（双模结合）**——底栏常驻极简快捷输入行（回车秒级入列） + 右侧点击大加号展开完整属性半屏抽屉（带 iOS 药丸拖拽手柄与物理阻尼曲线）。
   - **番茄钟形态**：**方案 A（经典拟物机械刻度盘）**——60 格分针细密刻度白表盘 + 大号时间数字 `24:52`（等宽排版防跳变）。
   - **任务完成展示**：**方案 A（就地划线保留）**——点击复选框弹性微回弹，钢笔墨水从左至右划过，文字原地变灰保留。

---

## 二、本地 SQLite 数据库模型设计 (Schema DDL)

```sql
-- 1. 版本迁移控制表 (保证版本迭代平滑升级，杜绝数据损坏)
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at DATETIME NOT NULL
);

-- 2. 待办任务表
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  notes TEXT,
  priority TEXT CHECK(priority IN ('P1','P2','P3','P4','P5')),
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
```

---

## 三、工程结构与运行指南

本项目分为现代化客户端、后端微服务与独立设计原型：

```
todo/
├── client/              # 客户端工程 (Vite + TypeScript + SQLite 3 WebAssembly + 自动迁移)
│   ├── src/
│   │   ├── db/          # SQLite 3 核心引擎、Schema 迁移、数据仓库 (Task/Pomo/Stats/Category)
│   │   │   ├── migrations/ # SQL 版本迁移文件 (001_initial_schema.sql)
│   │   │   ├── engine.ts   # SQLite 嵌入式引擎、导出导入、外键约束维护
│   │   │   ├── storage.ts  # IndexedDB 物理二进制持久化
│   │   │   └── repositories/ # 数据仓储 CRUD 与业务统计
│   │   ├── main.ts      # 客户端交互主入口与数据绑定
│   │   └── style.css    # 正统马尔斯绿 (#008779) 视觉体系与 Emil Kowalski 动效
│   └── tests/           # 自动化测试 (Vitest，覆盖迁移幂等性、外键约束、二进制导出导入)
├── backend/             # 云端服务 (NestJS + Prisma + PostgreSQL + Redis)
└── design/              # 原始交互审查与高保真设计原型
```

### 1. 客户端快速启动 (推荐)

```bash
cd client
npm install
npm run dev        # 启动热重载开发服务器
npm test           # 运行 SQLite 核心引擎与迁移测试 (7/7 全部通过)
npm run build      # 生产环境打包构建
```

### 2. 后端服务启动

```bash
cd backend
npm install
npm run start:dev  # 启动 NestJS 服务
```

### 3. 本地独立设计原型查验

```bash
file:///d:/work/todo/design/index.html
```
