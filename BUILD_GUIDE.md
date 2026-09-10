# PomoDo 原生 Android 打包构建与自动化发布手册

本项目规范区分 **「日常测试打包」** 与 **「标准化正式发布流水线」** 两个脚本，杜绝 50MB 二进制导致 Git 历史膨胀，并保证版本号与应用内更新完全同步。

---

## 🚀 方式 A：自动化一键正式发布 (Release Pipeline)

当需要对外正式发布新版本时，直接运行工作区根目录的 `release.ps1`：

```powershell
# 1. 自动交互式运行 (脚本自动推算下一个补丁版本号，回车即可)
powershell -ExecutionPolicy Bypass -File d:\work\todo\release.ps1

# 2. 或指定版本号与更新日志单行运行
powershell -ExecutionPolicy Bypass -File d:\work\todo\release.ps1 -Version "1.0.2" -Notes "优化专注划线与分类管理"
```

### 流水线自动执行的 6 大标准动作：
1. **版本自动同步**：自动将版本号同步至 `pomodo/pubspec.yaml` 与 `update_service.dart`（解决应用内更新检测脱节）。
2. **C 盘防爆隔离**：统一将缓存挂载在 `D:\pub_cache` 与 `D:\gradle_home`。
3. **质量分析门禁**：自动执行 `flutter analyze`，若有语法或类型错误立即熔断退出，杜绝带病发布。
4. **Release APK 编译**：使用 Flutter 原生编译并归档至 `dist/PomoDo_v{Version}_Android.apk`。
5. **Git 代码提交**：提交纯代码变更，自动排除大体积 APK 二进制，保护 `.git` 仓库健康不膨胀。
6. **GitHub Releases 自动挂载**：调用 `gh cli` 自动打 Tag、创建官方 Release 并上传 APK Asset，生成官方高速直链。

---

## 🛠️ 方式 B：本地日常测试打包 (Build APK Only)

如果只是在本地写完代码想快速打一个 APK 传到模拟器或测试机自测，不发布到 GitHub：

```powershell
powershell -ExecutionPolicy Bypass -File d:\work\todo\build_apk.ps1
```

- 该脚本仅在本地编译，生成包位于 `pomodo/build/app/outputs/flutter-apk/app-release.apk` 与根目录。
- 不会触发 Git 提交与 GitHub Releases 发布。

---

## ⚙️ 核心环境与防踩坑注意

### 1. 核心环境变量
```powershell
$env:PUB_CACHE = "D:\pub_cache"
$env:GRADLE_USER_HOME = "D:\gradle_home"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:JAVA_HOME = "D:\Java\jdk-17"
$env:PATH = "D:\flutter\bin;D:\Java\jdk-17\bin;$env:PATH"
```

### 2. 关键避坑准则
1. **严禁将 50MB+ 的 APK 强行 `git add` 进仓库分支**：Git 对大型二进制无差量算法，多次提交会导致克隆极慢且触发 GitHub 50MB 大文件告警。所有 APK 安装包统一托管在 GitHub Releases。
2. **跨驱动器 Kotlin 增量编译异常**：`android/gradle.properties` 中已配置 `kotlin.incremental=false`，防止 Windows 下跨 C/D 盘相对路径计算报错。
3. **国内镜像加速**：Gradle wrapper 已配置腾讯云高速镜像，Maven 已配置阿里云镜像，无需翻墙即可秒级解析依赖。
