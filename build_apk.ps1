<#
.SYNOPSIS
  PomoDo Flutter 原生 Android 一键离线打包脚本 (纯本地、防 C 盘爆满、竖屏锁定、Release 极速瘦身)
#>

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host " [PomoDo] 正在初始化 Flutter Android 原生构建环境... " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# 1. 环境变量配置 (保护 C 盘空间，统一归纳至 D 盘)
$env:PUB_CACHE = "D:\pub_cache"
$env:GRADLE_USER_HOME = "D:\gradle_home"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:JAVA_HOME = "D:\Java\jdk-17"
$env:PATH = "D:\flutter\bin;D:\Java\jdk-17\bin;$env:PATH"

$projectDir = "d:\work\todo\pomodo"
Set-Location $projectDir

Write-Host "[1/4] 执行依赖同步 (flutter pub get)..." -ForegroundColor Yellow
& flutter pub get

Write-Host "[2/4] 执行静态代码分析 (flutter analyze)..." -ForegroundColor Yellow
& flutter analyze

Write-Host "[3/4] 启动轻量 Release APK 编译 (flutter build apk --release)..." -ForegroundColor Yellow
& flutter build apk --release

$apkSrc = "$projectDir\build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "d:\work\todo\PomoDo_v1.0.0_Android.apk"

if (Test-Path $apkSrc) {
    Copy-Item $apkSrc $apkDest -Force
    $fileInfo = Get-Item $apkDest
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " √ 构建成功！通用正式版 APK 已归档至:" -ForegroundColor Green
    Write-Host "   $($fileInfo.FullName)" -ForegroundColor White
    Write-Host "   大小: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Green
} else {
    Write-Error "未找到 APK 构建产物，请检查构建日志！"
}
