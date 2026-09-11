# Google Play 商店上架完整申报材料与实战指南 (PomoDo)

> 本文档为 **PomoDo (Pomodoro × ToDo)** 上架 Google Play Console (开发者后台) 的标准化材料清单。  
> 包含符合 Google Play 政策的完整中英文案、分类标签、IARC 分级问卷、Data Safety 数据安全表单填报模板、视觉素材尺寸规范与 Android App Bundle (`.aab`) 签名打包指令。

---

## 目录
1. [一、 基础元数据 (Store Listing Metadata)](#一-基础元数据-store-listing-metadata)
2. [二、 应用分类与标签 (Category & Tags)](#二-应用分类与标签-category--tags)
3. [三、 图形与设计素材 (Graphic Assets)](#三-图形与设计素材-graphic-assets)
4. [四、 数据安全表单填报指南 (Data Safety Questionnaire)](#四-数据安全表单填报指南-data-safety-questionnaire)
5. [五、 内容分级问卷 (IARC Rating)](#五-内容分级问卷-iarc-rating)
6. [六、 目标受众与政策合规 (Target Audience & Content)](#六-目标受众与政策合规-target-audience--content)
7. [七、 隐私政策公开外链 (Privacy Policy URL)](#七-隐私政策公开外链-privacy-policy-url)
8. [八、 AAB 签名与编译构建全流程 (Technical Release - AAB)](#八-aab-签名与编译构建全流程-technical-release---aab)
9. [九、 个人开发者 20 人封闭测试合规应对策略](#九-个人开发者-20-人封闭测试合规应对策略)

---

## 一、 基础元数据 (Store Listing Metadata)

> 提示：Google Play 建议将 **英文 (en-US)** 设为默认语言，同时添加 **简体中文 (zh-CN)** 本地化列表。

### 1. 英文版 (Default: English - United States)

* **App name (应用名称)**（上限 30 字符）：  
  `PomoDo: Focus Timer & ToDo List` *(29 字符)*

* **Short description (简短说明)**（上限 80 字符）：  
  `Minimalist focus timer & GTD tasks. Things 3 flow with Apple activity rings.` *(74 字符)*

* **Full description (完整说明)**（上限 4000 字符）：
```markdown
Master your time, enter deep flow, and accomplish what truly matters with PomoDo.

PomoDo is a distraction-free, privacy-first productivity tool designed around the timeless principles of Dieter Rams: less, but better. Seamlessly merging the purity of the Things 3 dual-track workflow with the mechanical beauty of analog chronometers and Apple Activity Rings, PomoDo offers an unmatched time management experience.

━━━━━━━━━━━━━━━━━━━━
✨ KEY HIGHLIGHTS
━━━━━━━━━━━━━━━━━━━━

📥 1. Things 3 Dual-Track Flow (Inbox & Today)
• Dedicated Inbox: Capture sudden sparks, ideas, and errands instantly without deadlines. Free your mind.
• Clean Today View: Zero noise. Shows strictly what is due today and rolled-over tasks.
• Ivy Lee Priority (Top 5): Focus on the 5 critical core tasks with drag-and-drop reordering.
• All-Done Celebration: Experience a full-screen, tactile celebration when you clear your daily agenda.

🍅 2. Bilateral Focus × Task Lifecycle
• Auto-Settle on Completion: Check off a task while focusing, and PomoDo automatically logs your elapsed focus minutes into the database and unbinds the session.
• Flow Protection: Deleting an active task gracefully switches the timer to free-flow mode without cutting off your momentum.
• Focus Conflict Resolver: Settle, discard, or switch smoothly between tasks with a single tap.
• Responsive Live Dial: Task updates reflect instantaneously on your timer dial.

⭕ 3. Apple-Inspired Activity Rings & Logbook
• Dual Activity Rings: Track your Task Completion Rate (outer ring) and Focus Goal Rate (inner ring) on an elegant Canvas display.
• Unified Time Dimension: Seamlessly toggle between "Today" and "This Week" with synchronized statistical criteria.
• Category Time Investment: Visual breakdown showing precisely where your energy and hours were spent.
• Logbook Archive: A dedicated space to revisit completed milestones, intelligently grouped by date with one-tap restoration.

🎧 4. Gapless Hardware-Grade Soundscapes
• Pure offline ambient sound loops engineered with just_audio (LoopMode.one).
• 🌧️ Window Rain · 🌊 Deep Ocean Tides · 🌲 Midnight Campfire.
• Gentle 1.0-second fade-in and 0.5-second fade-out to protect your hearing from sudden abrupt audio cuts.

🎨 5. Bauhaus Color Themes & Full Dark Mode
• Curated Bauhaus palettes: Mars Green (Signature #008779), Sky Blue, Lavender Purple, Amber Orange, and Obsidian Slate.
• Deep system-adaptive Dark Mode for OLED battery efficiency and nighttime focus comfort.

━━━━━━━━━━━━━━━━━━━━
🔒 PRIVACY-FIRST & ZERO TRACKING
━━━━━━━━━━━━━━━━━━━━

• 100% Local SQLite Database: All your tasks, notes, and focus history stay strictly on your local device.
• Zero Ads, Zero Telemetry: No third-party trackers, no behavioral profiling, and no remote data harvesting.
• Offline Freedom: Works completely without an active internet connection.
• Database Export: Export and back up your complete physical `.db` database at any time.

Start your mindful focus journey today with PomoDo.
```

---

### 2. 中文版 (Localized: Chinese - Simplified)

* **应用名称**（上限 30 字符）：  
  `PomoDo: 极简番茄钟待办与时间管理` *(23 字符)*

* **简短说明**（上限 80 字符）：  
  `极简时间管理利器。融合 Things 3 双轨待办、拟物番茄钟与 Apple 效能闭环。` *(42 字符)*

* **完整说明**（上限 4000 字符）：
```markdown
掌控每日要务，进入深度心流，达成真正重要之事。

PomoDo 是一款专注高效、以隐私为先的极简时间管理利器。我们汲取德国博朗“少，却更好 (Less, but better)”的设计工学，融合 Things 3 纯粹双轨待办流、经典拟物机械番茄表盘与 Apple 效能闭环双环，带来极为舒适、专注的时间管理体验。

━━━━━━━━━━━━━━━━━━━━
✨ 核心功能亮点
━━━━━━━━━━━━━━━━━━━━

📥 1. Things 3 纯粹双轨心流 (收集箱 & 今日)
• 独立收集箱 (Inbox)：灵感念头秒级捕获入列，不设硬性截止日，彻底解放大脑内存；
• 纯净今日 (Today)：拒绝无度堆积，仅聚焦“今日截止”与“昨日顺延”的核心要务；
• 艾利 5 件事法则：智能区分 Top 5 核心待办与候补缓冲池，支持长按拖拽调序与轻触感反馈；
• 今日达成庆祝：全部搞定今日要务时触发全屏庆祝动效，赋予充足的正向心理激励。

🍅 2. 待办与番茄全生命周期联合处理
• 完成自动结算存盘：任务进行中打勾或滑屏完成，自动按有效专注分钟入库并解绑，绝不浪费每一秒专注努力；
• 心流降级防护：删除正在专注的任务时，倒计时绝不强制截断，自动平滑降级为自由专注；
• 并发专注冲突拦截：跨任务专注时智能弹出【结算并切换】、【放弃并切换】、【继续当前】；
• 响应式动态联动：待办改名与属性变更即时映射至番茄表盘，告别静态快照滞后。

⭕ 3. Apple 效能闭环双环 & 历史归档室
• 物理双环图表：外环呈现「今日任务达成率」，内环呈现「专注目标达成率」，极简高级；
• 今日/本周统一度量：支持随时在今日与本周双维度间自由切换，口径严格对齐；
• 时间投资分布条：横向多段色彩条，直观呈现时间具体投资到了哪些领域；
• 历史归档室 (Logbook)：独立专属归档页，支持关键词检索、时间倒序智能分组，支持一键撤销并复原为待办。

🎧 4. 100% 硬件级自然声景采样
• 基于底层的真实硬件级零间隙无缝循环 (Gapless Loop)；
• 实录自然采样：🌧️ 窗台夜雨 · 🌊 深海潮汐 · 🌲 夜色篝火；
• 配备 1.0 秒柔和淡入与 0.5 秒平滑淡出，消除声音突兀顿挫。

🎨 5. 五套包豪斯色彩体系与深浅双模
• 经典马尔斯绿 (#008779)、晴空蓝、丁香紫、琥珀橙、黑曜石全量切换；
• 深度适配系统级深色/浅色模式，状态栏与导航栏沉浸式响应；
• 完整中英双语国际化支持。

━━━━━━━━━━━━━━━━━━━━
🔒 100% 本地离线与隐私保护
━━━━━━━━━━━━━━━━━━━━

• 本地嵌入式 SQLite：所有待办、笔记与专注流水严格存储在您的本机内部存储中；
• 零广告、零追踪：无任何第三方统计/广告 SDK，不收集、不上传任何个人信息；
• 完全离线可用：无网络环境下功能 100% 畅通无阻；
• 数据库自由备份：在「设置 -> 数据库中心」可随时导出物理 `.db` 数据库备份或迁移。

让专注回归专注，开启高质感的时间心流之旅。
```

---

## 二、 应用分类与标签 (Category & Tags)

* **应用类别 (Application Type)**：应用 (App)
* **默认类别 (Category)**：效率 (Productivity)
* **标签 (Tags)**（在 Console 中最多选择 5 个）：
  1. `To-do list` (待办清单)
  2. `Pomodoro` (番茄钟)
  3. `Productivity` (效率)
  4. `Time management` (时间管理)
  5. `Habit tracker` (习惯养成)
* **开发者联系方式 (Developer Contact Details)**：
  - **Email**：`chonggao9@gmail.com`
  - **Website**：`https://github.com/chonggao9/pomodo`
  - **Privacy Policy URL**：`https://chonggao9.github.io/pomodo/privacy-policy.html`

---

## 三、 图形与设计素材 (Graphic Assets)

所有素材已高规格准备完毕，保存在项目目录 `store_assets/google_play/` 中：

| 资产类型 | 规格要求 | 对应文件路径 | 状态 |
| :--- | :--- | :--- | :--- |
| **应用图标 (App Icon)** | 512 × 512 px, 32 位 PNG, 最大 1024 KB | [`store_assets/google_play/app_icon_512x512.jpg`](file:///d:/work/todo/store_assets/google_play/app_icon_512x512.jpg) | ✅ 已就绪 |
| **置顶大图 (Feature Graphic)** | 1024 × 500 px, JPG/PNG, 比例约 2:1, 无透明 | [`store_assets/google_play/feature_graphic_1024x500.jpg`](file:///d:/work/todo/store_assets/google_play/feature_graphic_1024x500.jpg) | ✅ 已生成高保真官方展台图 |
| **手机截屏 (Screenshots)** | 16:9 或 9:16，每边介于 320px 与 3840px 之间 (推荐 1080×1920)，至少 4 张 | 运行 App 在模拟器/真机截图（见下方截图指引） | 建议截取 5 核心张 |

### 推荐截图清单与宣传配字：
1. **截图 1 (今日待办)**：*Things 3 双轨心流 · 独立收集箱与今日聚焦*
2. **截图 2 (拟物表盘)**：*博朗经典机械刻度 · 自然实录白噪音心流*
3. **截图 3 (效能闭环)**：*Apple Activity Rings 闭环 · 统一度量看板*
4. **截图 4 (历史归档)**：*Logbook 档案室 · 智能时间倒序与一键复原*
5. **截图 5 (主题风格)**：*包豪斯五大经典色彩 · 深度暗黑模式*

---

## 四、 数据安全表单填报指南 (Data Safety Questionnaire)

Google Play 对 **Data Safety** 审核极其严格。因为 PomoDo 为 **100% 纯本地 SQLite 存储、无云端同步、无第三方 SDK**，因此可以直接如实勾选最安全的极简选项，**极速通过审核**：

| 问卷题目 | 官方推荐选择 | 详细填报说明 |
| :--- | :--- | :--- |
| **Does your app collect or share any required user data types?**<br>(您的应用是否收集或共享任何必填的用户数据类型？) | **No (否)** | PomoDo 完全本地运行，没有任何数据出网传输。 |
| **Is all of the user data collected by your app encrypted in transit?**<br>(收集的数据在传输中是否加密？) | **N/A (不适用)** | 应用不收集数据，也不传输数据。 |
| **Do you provide a way for users to request that their data be deleted?**<br>(是否提供用户申请删除其数据的途径？) | **Yes (是)** | 用户可在应用的「设置 -> 数据库中心」随时点击「清空/重置数据库」，卸载应用也会彻底删除本地沙盒数据库。 |

---

## 五、 内容分级问卷 (IARC Rating)

在 Google Play Console 点击「内容分级」，填写 IARC 问卷：
1. **类别**：选择 `公用事业、效率、生产力及其他应用 (Utility, Productivity)`；
2. **暴力**：否；
3. **性**：否；
4. **粗俗言语**：否；
5. **受控物质 (烟/酒/毒品)**：否；
6. **是否允许用户互动或交换内容**：否；
7. **是否与第三方共享用户的物理位置**：否；
8. **是否允许购买数字商品 (内购)**：否；
- **评估结果**：自动评定为 **PEGI 3 / Everyone (适合所有人 / 全年龄)**。

---

## 六、 目标受众与政策合规 (Target Audience & Content)

1. **目标年龄层**：
   - 勾选：`13-15 岁`、`16-17 岁`、`18 岁及以上`。
   - **严禁勾选 13 岁以下**（否则会被列入儿童应用计划，触发极其苛刻的 COPPA 审核审查）。
2. **宣传是否存在吸引儿童的要素**：
   - 选择：`No (否)`（PomoDo 属于专业效率工具，设计语言成熟克制）。
3. **广告**：
   - 选择：`No, my app does not contain ads (否，不包含广告)`。
4. **金融功能 / 政府应用 / 健康应用**：
   - 全部选择：`No (否)`。

---

## 七、 隐私政策公开外链 (Privacy Policy URL)

Google Play 要求应用必须附带一个可通过浏览器公网公开访问的有效 Privacy Policy 网址。

* **已就绪的静态页面**：[`docs/privacy-policy.html`](file:///d:/work/todo/docs/privacy-policy.html)
* **GitHub Pages 线上公开访问地址**：  
  `https://chonggao9.github.io/pomodo/privacy-policy.html`  
  *(或者直接使用 GitHub Raw / Gist 地址：`https://github.com/chonggao9/pomodo/blob/main/PRIVACY_POLICY.md`)*

---

## 八、 AAB 签名与编译构建全流程 (Technical Release - AAB)

Google Play 自 2021 年起已**全面停用 APK 上架**，必须提交 **Android App Bundle (`.aab`)** 格式。

### 步骤 1：生成正式发布用密钥库 (Keystore)

在终端运行以下标准 Java Keytool 命令生成密钥库文件（推荐存放在 `d:\work\todo\upload-keystore.jks`）：

```powershell
keytool -genkey -v -keystore d:\work\todo\upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias pomodo_upload_key
```
> 系统会提示输入密钥密码、姓名、组织名称等。请务必牢记设置的密码并妥善备份 `upload-keystore.jks`！

### 步骤 2：配置 `key.properties`

将 `pomodo/android/key.properties.example` 复制为 `pomodo/android/key.properties`，并填写密码与路径：

```properties
storePassword=您设置的密钥密码
keyPassword=您设置的密钥密码
keyAlias=pomodo_upload_key
storeFile=d:\\work\\todo\\upload-keystore.jks
```

### 步骤 3：一键编译 Google Play 专用的 Release AAB

在终端执行编译命令：

```powershell
$env:PUB_CACHE="D:\pub_cache"
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
$env:GRADLE_USER_HOME="D:\gradle_home"
$env:ANDROID_HOME="D:\Android\Sdk"
$env:JAVA_HOME="D:\Java\jdk-17"
$env:PATH="D:\flutter\bin;D:\Java\jdk-17\bin;$env:PATH"

cd d:\work\todo\pomodo
flutter build appbundle --release
```

- **编译产物路径**：  
  `d:\work\todo\pomodo\build\app\outputs\bundle\release\app-release.aab`
- 此 `.aab` 文件即可直接拖拽上传至 Google Play Console 的「正式发布 (Production)」或「测试版 (Testing)」轨道。

---

## 九、 个人开发者 20 人封闭测试合规应对策略

> ⚠️ **Google 2023 年 11 月新政**：所有在 2023 年 11 月 13 日之后注册的**个人开发者账号**，在发布正式版前，必须在封闭测试 (Closed Testing) 中经过 **至少 20 位测试人员连续连续测试 14 天** 后方可申请正式上线。

### 应对指南与操作步骤：
1. **创建封闭测试轨道 (Closed Testing)**：在 Console 中新建一个测试轨道，上传已构建的 `.aab` 包；
2. **收集 20 个 Google 账号**：
   - 可邀请身边的同事、朋友、开发者社群（如 Reddit `r/AndroidClosedTesting`、V2EX、即刻、Discord 等开发者互助组织）；
   - 在后台「测试人员」列表中创建 Google 群组或输入 20+ 个 Gmail 邮箱；
3. **分发 Opt-in 链接**：将 Google Play 提供的加入测试链接发给这 20 位测试者，确保他们在手机端点击「接受邀请」并安装下载；
4. **保持 14 天活跃**：建议在群组内提醒测试人员在此 14 天内保持应用安装并不定期打开体验；
5. **申请生产环境发布 (Apply for Production)**：14 天倒计时结束后，Console 后台会自动解锁「申请正式上线」按钮，提交后通常 1~3 个工作日即可通过正式上架！
