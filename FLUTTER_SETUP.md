# Flutter 开发环境安装指南（Windows）

## 1. 下载 Flutter SDK

访问官网下载并解压到 `C:\flutter`：
https://docs.flutter.dev/get-started/install/windows

或使用命令行：
```powershell
# 方式 A：winget 安装（推荐）
winget install -e --id Google.Flutter

# 方式 B：手动下载解压后配置 PATH
$env:PATH += ";C:\flutter\bin"
```

## 2. 配置环境变量（持久化）

```powershell
[Environment]::SetEnvironmentVariable(
  "PATH",
  $env:PATH + ";C:\flutter\bin",
  "User"
)
```

## 3. 验证安装

```powershell
flutter doctor
```

## 4. 安装 Android Studio

下载：https://developer.android.com/studio
- 安装时勾选 Android SDK
- 配置 Android SDK 路径

```powershell
flutter config --android-sdk C:\Users\<你的用户名>\AppData\Local\Android\Sdk
flutter doctor --android-licenses   # 同意所有许可证
```

## 5. 创建 Flutter 项目

安装好 Flutter 后，在项目根目录执行：
```powershell
cd D:\work\todo
flutter create flowtask --org com.flowtask --platforms android,web
```

## 6. 运行

```powershell
cd flowtask
flutter pub get
flutter run -d chrome    # Web 端
flutter run -d android   # Android（需连接设备或启动模拟器）
```

---
> 注：目前 Flutter SDK 未安装，后端已先行搭建完成。
> 安装 Flutter 后即可执行上述步骤创建客户端项目。
