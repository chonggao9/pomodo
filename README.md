# PomoDo (Pomodoro × ToDo 极简时间管理)

<div align="center">

![PomoDo Logo](https://img.shields.io/badge/PomoDo-v1.0.5-008779?style=for-the-badge&logo=flutter&logoColor=white)
[![GitHub Release](https://img.shields.io/github/v/release/chonggao9/pomodo?style=for-the-badge&color=0284C7)](https://github.com/chonggao9/pomodo/releases/tag/v1.0.5)
[![License](https://img.shields.io/badge/License-MIT-334155?style=for-the-badge)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-EA580C?style=for-the-badge)](https://flutter.dev)

**融合 Things 3 纯粹双轨流、Apple Activity Rings 效能闭环与博朗拟物工学的原生时间管理利器**  
*正统官方「马尔斯绿 (`#008779`)」· 全面暗黑模式 · 本地 SQLite 3 嵌入式存储*

[📥 立即下载最新 Android Release (v1.0.5)](https://github.com/chonggao9/pomodo/releases/download/v1.0.5/PomoDo_v1.0.5_Android.apk) · [🌟 网页版在线预览](https://chonggao9.github.io/pomodo/) · [📜 查看更新日志](walkthrough.md)

</div>

---

## 📱 核心特性与设计哲学

### 1. 📥 Things 3 纯粹双轨心流体系
- **独立收集箱 (Inbox)**：所有灵感想法秒级入列，不设截止日，彻底解放大脑内存；
- **纯净今日 (Today)**：仅聚合“今日截止”与“历史顺延”任务，远离无效堆积；
- **今日全搞定成就反馈**：清空今日全部核心待办时触发全屏庆祝动效，赋予充实的正向心理激励；
- **艾利容量防爆缓冲池**：智能区分 Top 5 核心要务与候补缓冲区，手势长按物理拖拽排序，支持左右轻滑快捷完成与删除撤销。

### 2. 🍅 待办与番茄全生命周期联合处理
- **完成自动结算**：勾选或右滑完成任务时，若番茄钟正在专注该任务，自动按有效分钟数结算存盘、写入 SQLite 流水并解绑，杜绝时间浪费；
- **心流降级保护**：删除正在专注的任务时，倒计时不粗暴截断，自动平滑降级为自由专注；
- **并发冲突拦截**：专注任务 A 时点任务 B 专注，呼出冲突弹窗支持【结算并切换】、【放弃并切换】、【继续当前】；
- **动态响应式联动**：番茄表盘下方任务信息直接响应 Provider 状态流，改名改属性即时刷新，告别快照滞后。

### 3. 🛡️ 五大隐藏高危风险代码级防御
1. **防御 Android 锁屏 Doze 挂起**：放弃脆弱的 `Timer.periodic` 单纯累加，全面采用绝对物理时间戳 `_targetEndTime` 计算剩余秒数，锁屏唤醒秒级精确对齐；
2. **防御删除撤销 (Undo) 外键断链**：任务删除瞬间内存缓存其关联的历史 Session ID，4 秒内点击撤销时在 SQLite 事务中原子恢复关联，历史资产（`🍅 count`）100% 完美复原；
3. **防御微时段垃圾数据污染**：实际专注 < 60 秒的误触会话自动拦截丢弃，不入库、不产生脏流水；
4. **防御并发属性竞态**：弹窗式友好接管冲突，状态机严格约束切换流程；
5. **防御跨午夜顺延统计漂移**：番茄流水忠实记录实际物理时间戳（`startedAt`），待办状态以自身 `completedAt` 为准，双轨互不干扰。

### 4. ⭕ Apple Activity Rings 效能闭环与 Logbook 归档室
- **Canvas 物理双环**：外环展示「今日待办达成率」，内环展示「专注目标达成率」，半径安全钳制与零除防护；
- **今日 / 本周双维度对齐**：支持今日与本周双向切换，待办达成量与专注时长口径严格统一；
- **分类时间投资分布**：直观横向多段条，清晰呈现时间具体投资到了哪些任务领域；
- **Things 3 历史归档室 (Logbook)**：独立全功能页面，支持按标题备注实时检索，按时间智能倒序分组（今天/昨天/本周较早/更早月份），支持一键复原为待办。

### 5. 🎨 五套包豪斯色彩体系与深色双模
- **正统官方马尔斯绿 (`#008779`)**、**晴空蓝 (`#0284C7`)**、**丁香紫 (`#7C3AED`)**、**琥珀橙 (`#EA580C`)**、**黑曜石 (`#334155`)** 全 App 统一驱动；
- 全量适配系统级 **浅色 / 深色模式**，状态栏与导航条即时沉浸式响应；
- 完整 **中英双语 (zh-CN / en-US)** 国际化支持。

### 6. 🎧 100% 硬件级自然声景 (White Noise)
- 基于 `just_audio` 底层引擎，实现真硬件级零间隙无缝循环 (Gapless Loop)；
- 内置自然采样：**🌧️ 窗台夜雨**、**🌊 深海潮汐**、**🌲 夜色篝火**，配备 1.0s 平滑淡入与 0.5s 柔和淡出。

---

## 🗄️ 本地 SQLite 数据库模型设计 (Schema DDL)

```sql
-- 1. 版本迁移控制表 (保证版本迭代平滑升级，杜绝数据损坏)
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at DATETIME NOT NULL
);

-- 2. 待办任务表 (包含 Things 3 收集箱双轨与完成时间戳)
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  notes TEXT,
  priority TEXT CHECK(priority IN ('P1','P2','P3','P4','P5')),
  ivy_order INTEGER DEFAULT 1,
  status TEXT CHECK(status IN ('pending','completed','archived')) DEFAULT 'pending',
  workload TEXT CHECK(workload IN ('easy','medium','hard')) DEFAULT 'easy',
  due_date TEXT,               -- NULL 表示收集箱 (Inbox)，YYYY-MM-DD 表示指定日期
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

-- 4. 番茄专注记录表 (支持外键原子重连与防抖保护)
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

## 📂 工程目录结构

```
todo/
├── pomodo/                      # Flutter 原生应用核心工程
│   ├── lib/
│   │   ├── core/                # 底层核心基础设施
│   │   │   ├── database/        # SQLite 3 引擎、增量迁移与外键事务维护
│   │   │   ├── i18n/            # 中英全量国际化字典 (AppStrings)
│   │   │   ├── services/        # 自然声景引擎 (just_audio) 与应用内检查更新
│   │   │   └── theme/           # 包豪斯 5 色体系、深浅主题定义与辅助工具
│   │   ├── models/              # 数据实体模型 (Task, Subtask, PomodoroSession)
│   │   ├── providers/           # 响应式状态流 (TaskProvider, PomodoroProvider, ProfileProvider)
│   │   ├── views/               # 四大核心视图
│   │   │   ├── today/           # 今日待办、收集箱、详情抽屉与艾利缓冲池
│   │   │   ├── pomodoro/        # 拟物机械表盘与专注心流
│   │   │   ├── stats/           # Apple 闭环双环看板与 Logbook 历史归档室
│   │   │   └── profile/         # 主题切换、中英文切换、数据库导出导入与更新
│   │   └── widgets/             # 核心组件库 (表盘 Painter、滑动胶囊、双环等)
│   ├── test/                    # 自动化单元测试与 Widget 测试套件 (18/18 100% PASS)
│   └── pubspec.yaml             # 依赖与版本定义 (v1.0.5+6)
├── release.ps1                  # 全自动化构建、静态门禁与 GitHub Release 发布流水线
├── dist/                        # 本地 Release 安装包归档输出目录
└── README.md                    # 项目核心指南
```

---

## 🚀 快速启动与构建

### 1. 运行环境要求
- **Flutter SDK**: `^3.13.2` 或更高
- **Dart SDK**: `^3.1.0`
- **JDK**: Java 17
- **Android SDK**: API 34 (Android 14)

### 2. 启动开发调试

```bash
cd pomodo

# 获取依赖包
flutter pub get

# 启动本地热重载调试 (连接 Android 设备或模拟器)
flutter run

# 运行代码规范质量门禁
flutter analyze

# 运行全套自动化单元测试 (18 项测试)
flutter test
```

### 3. 构建发布版本与发版流水线

工程根目录内置了一键自动化发版脚本 `release.ps1`，执行版本号同步、门禁审查、R8 编译优化、Git 提交推送以及 GitHub Release 自动发布：

```powershell
# 执行全自动化发版 (升级版本号、编译 Release APK、发布 GitHub Release)
.\release.ps1 -Version "1.0.5" -Notes "待办与番茄全生命周期联合处理、5大高危风险防御、Things 3 收集箱双轨流、Logbook历史归档室、Apple双环闭环与五套包豪斯色彩体系"
```

编译出的 APK 产物位于 `dist/PomoDo_v1.0.5_Android.apk`，可直接分发安装。

---

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。欢迎 Star 与 Issue 建议！
