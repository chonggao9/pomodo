<#
.SYNOPSIS
  PomoDo Android 原生全自动一键发布流水线 (Release Pipeline)
  涵盖：版本自动同步 -> 质量分析门禁 -> Release APK 编译 -> 历史仓库瘦身 -> Git 提交 -> GitHub Releases 官方发布

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\release.ps1 -Version "1.0.2" -Notes "修复专注划线动效与分类展示"
  powershell -ExecutionPolicy Bypass -File .\release.ps1
#>

param(
    [string]$Version,
    [string]$Notes
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "   PomoDo 自动化发布流水线 (Release Pipeline)   " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$rootDir = "d:\work\todo"
$projectDir = "$rootDir\pomodo"
$pubspecPath = "$projectDir\pubspec.yaml"
$updateServicePath = "$projectDir\lib\core\services\update_service.dart"

# ---------------------------------------------------------
# 1. 自动计算与确认版本号
# ---------------------------------------------------------
$currentPubspec = Get-Content $pubspecPath -Raw
if ($currentPubspec -match 'version:\s*(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $buildNum = if ($matches[4]) { [int]$matches[4] + 1 } else { 2 }
    $suggestedVersion = "$major.$minor.$($patch + 1)"
} else {
    $suggestedVersion = "1.0.2"
    $buildNum = 2
}

if (-not $Version) {
    Write-Host "当前建议发布的下一个版本为: " -NoNewline
    Write-Host "v$suggestedVersion" -ForegroundColor Green
    $inputVer = Read-Host "请输入目标发布版本号 (直接回车默认 $suggestedVersion)"
    if ($inputVer -and $inputVer.Trim() -ne "") {
        $Version = $inputVer.Trim().TrimStart('v').TrimStart('V')
    } else {
        $Version = $suggestedVersion
    }
} else {
    $Version = $Version.Trim().TrimStart('v').TrimStart('V')
}

if (-not $Notes -or $Notes.Trim() -eq "") {
    $inputNotes = Read-Host "请输入本次发布更新摘要 (直接回车默认: 体验优化与细节完善)"
    if ($inputNotes -and $inputNotes.Trim() -ne "") {
        $Notes = $inputNotes.Trim()
    } else {
        $Notes = "性能提升、交互对齐与体验优化。"
    }
}

Write-Host "`n>>> [1/6] 同步版本号 v$Version (Build $buildNum)..." -ForegroundColor Yellow

# 更新 pubspec.yaml
$newPubspec = $currentPubspec -replace 'version:\s*\d+\.\d+\.\d+(\+\d+)?', "version: $Version+$buildNum"
Set-Content $pubspecPath -Value $newPubspec -NoNewline

# 更新 update_service.dart
if (Test-Path $updateServicePath) {
    $updateServiceContent = Get-Content $updateServicePath -Raw
    $newUpdateServiceContent = $updateServiceContent -replace "static const String currentVersion = '.*?';", "static const String currentVersion = '$Version';"
    Set-Content $updateServicePath -Value $newUpdateServiceContent -NoNewline
}

# ---------------------------------------------------------
# 2. 环境变量配置 (保护 C 盘空间，统一归纳至 D 盘)
# ---------------------------------------------------------
$env:PUB_CACHE = "D:\pub_cache"
$env:GRADLE_USER_HOME = "D:\gradle_home"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:JAVA_HOME = "D:\Java\jdk-17"
$env:PATH = "D:\flutter\bin;D:\Java\jdk-17\bin;$env:PATH"

Set-Location $projectDir

# ---------------------------------------------------------
# 3. 依赖同步与代码质量门禁 (Quality Gate)
# ---------------------------------------------------------
Write-Host ">>> [2/6] 执行依赖同步 (flutter pub get)..." -ForegroundColor Yellow
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "依赖同步失败，构建中断！"
    exit 1
}

Write-Host ">>> [3/6] 执行静态质量分析门禁 (flutter analyze)..." -ForegroundColor Yellow
& flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "静态分析存在语法报错或未通过检查，发布流水线已熔断，请先修复问题！"
    exit 1
}

# ---------------------------------------------------------
# 4. 纯本地 Release APK 编译构建
# ---------------------------------------------------------
Write-Host ">>> [4/6] 启动原生 Android Release 编译 (flutter build apk --release)..." -ForegroundColor Yellow
& flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "APK 编译失败！"
    exit 1
}

$apkSrc = "$projectDir\build\app\outputs\flutter-apk\app-release.apk"
$distDir = "$rootDir\dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$distApk = "$distDir\PomoDo_v${Version}_Android.apk"
$latestApk = "$distDir\PomoDo_Latest_Android.apk"

if (Test-Path $apkSrc) {
    Copy-Item $apkSrc $distApk -Force
    Copy-Item $apkSrc $latestApk -Force
    $apkInfo = Get-Item $distApk
    $apkSizeMB = [math]::Round($apkInfo.Length / 1MB, 2)
    Write-Host " √ APK 构建成功！文件大小: $apkSizeMB MB" -ForegroundColor Green
} else {
    Write-Error "未在 $apkSrc 找到构建产物！"
    exit 1
}

# ---------------------------------------------------------
# 5. Git 代码提交与仓库瘦身 (解除根目录 APK 的 blob 跟踪，防止仓库爆仓)
# ---------------------------------------------------------
Write-Host ">>> [5/6] 提交版本代码到 Git (主分支隔离大二进制)..." -ForegroundColor Yellow
Set-Location $rootDir

# 检查根目录下是否有名为 PomoDo_v*.apk 的文件被 git 缓存追踪，如有则解绑索引
git rm --cached PomoDo_v1.0.0_Android.apk 2>$null
git rm --cached PomoDo_Latest_Android.apk 2>$null

git add .
$commitMsg = "release: 发布 v$Version - $Notes"
git commit -m "$commitMsg" 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host " √ 代码成功提交到本地 Git。" -ForegroundColor Green
} else {
    Write-Host " - 暂无新的代码改动需提交，继续发布。" -ForegroundColor Gray
}

Write-Host "正在推送到 GitHub 远程仓库 (main)..." -ForegroundColor Yellow
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Warning "推送到 GitHub main 分支遇到网络波动，请稍后重试 git push。"
}

# ---------------------------------------------------------
# 6. GitHub Releases 官方自动发布与产物挂载
# ---------------------------------------------------------
Write-Host ">>> [6/6] 自动发布 GitHub Release (v$Version)..." -ForegroundColor Yellow

$tag = "v$Version"
$releaseTitle = "PomoDo v$Version 正式发布版"

# 调用 gh cli 发布 Release 并挂载 APK
& gh release create "$tag" "$distApk" --title "$releaseTitle" --notes "$Notes" --clobber
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n=================================================" -ForegroundColor Green
    Write-Host " ★ PomoDo v$Version 发布圆满成功！" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " 1. 本地归档包: $distApk ($apkSizeMB MB)" -ForegroundColor White
    Write-Host " 2. GitHub Release: https://github.com/chonggao9/pomodo/releases/tag/$tag" -ForegroundColor Cyan
    Write-Host " 3. APK 官方直链: https://github.com/chonggao9/pomodo/releases/download/$tag/PomoDo_v${Version}_Android.apk" -ForegroundColor Cyan
    Write-Host " 4. 客户端热更新: 已对齐最新版本号，应用内点击「检查更新」即可一键拉取！" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
} else {
    Write-Warning "调用 gh cli 发布 Release 失败，请检查网络或 GitHub 登录状态。"
}
