# PomoDo 原生 Android 打包与构建手册

## 极速一键打包
在终端或 PowerShell 中直接执行工作区根目录的打包脚本：
```powershell
powershell -ExecutionPolicy Bypass -File d:\work\todo\build_apk.ps1
```
脚本将自动挂载环境、执行语法自检、编译并在根目录生成最新的 **轻量正式版** `PomoDo_v1.0.0_Android.apk`（约 50MB，强制锁定竖屏与防大屏膨胀布局）。

---

## 手动构建与环境参数

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

### 2. 构建步骤
```powershell
cd d:\work\todo\pomodo
flutter pub get
flutter build apk --debug
```

### 3. 关键避坑注意
1. **防 C 盘爆满**：必须将 `PUB_CACHE` 和 `GRADLE_USER_HOME` 定向在 D 盘，不得回退至默认的用户根目录。
2. **跨驱动器 Kotlin 增量编译异常**：`android/gradle.properties` 中已配置 `kotlin.incremental=false`，防止 Windows 下跨 C/D 盘相对路径计算报错。
3. **国内镜像**：Gradle wrapper 已配置腾讯云高速镜像，Maven 已配置阿里云镜像。
