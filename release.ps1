param(
    [string]$Version,
    [string]$Notes
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "       PomoDo Release Pipeline (Automated)       " -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

$rootDir = "d:\work\todo"
$projectDir = "$rootDir\pomodo"
$pubspecPath = "$projectDir\pubspec.yaml"
$updateServicePath = "$projectDir\lib\core\services\update_service.dart"

# 1. Version Detection
$currentPubspec = [System.IO.File]::ReadAllText($pubspecPath, [System.Text.Encoding]::UTF8)
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
    Write-Host "Suggested release version: v$suggestedVersion" -ForegroundColor Green
    $inputVer = Read-Host "Enter release version (Press Enter for $suggestedVersion)"
    if ($inputVer -and $inputVer.Trim() -ne "") {
        $Version = $inputVer.Trim().TrimStart('v').TrimStart('V')
    } else {
        $Version = $suggestedVersion
    }
} else {
    $Version = $Version.Trim().TrimStart('v').TrimStart('V')
}

if (-not $Notes -or $Notes.Trim() -eq "") {
    $Notes = "Release v${Version} - Brownian noise upgrade and experience polish."
}

Write-Host ""
Write-Host "[1/6] Syncing version v$Version (Build $buildNum)..." -ForegroundColor Yellow

# Update pubspec.yaml
$newPubspec = $currentPubspec -replace 'version:\s*\d+\.\d+\.\d+(\+\d+)?', "version: $Version+$buildNum"
[System.IO.File]::WriteAllText($pubspecPath, $newPubspec, [System.Text.Encoding]::UTF8)

# Update update_service.dart
if (Test-Path $updateServicePath) {
    $updateServiceContent = [System.IO.File]::ReadAllText($updateServicePath, [System.Text.Encoding]::UTF8)
    $newUpdateServiceContent = $updateServiceContent -replace "static const String currentVersion = '.*?';", "static const String currentVersion = '$Version';"
    [System.IO.File]::WriteAllText($updateServicePath, $newUpdateServiceContent, [System.Text.Encoding]::UTF8)
}

# 2. Environment Setup (Protect C Drive)
$env:PUB_CACHE = "D:\pub_cache"
$env:GRADLE_USER_HOME = "D:\gradle_home"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:ANDROID_HOME = "D:\Android\Sdk"
$env:JAVA_HOME = "D:\Java\jdk-17"
$env:PATH = "D:\flutter\bin;D:\Java\jdk-17\bin;$env:PATH"

Set-Location $projectDir

# 3. Dependencies & Quality Gate
Write-Host "[2/6] Running flutter pub get..." -ForegroundColor Yellow
& flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter pub get failed!"
    exit 1
}

Write-Host "[3/6] Running flutter analyze quality gate..." -ForegroundColor Yellow
& flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter analyze found issues! Pipeline aborted."
    exit 1
}

# 4. Compile Release APK
Write-Host "[4/6] Building Android Release APK (flutter build apk --release)..." -ForegroundColor Yellow
& flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "flutter build apk failed!"
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
    Write-Host "OK: APK Build successful! Size: $apkSizeMB MB" -ForegroundColor Green
} else {
    Write-Error "Could not find build output at $apkSrc"
    exit 1
}

# 5. Git Commit & Push
Write-Host "[5/6] Committing code changes to Git..." -ForegroundColor Yellow
Set-Location $rootDir

git add .
$commitMsg = "release: v$Version - $Notes"
git commit -m "$commitMsg"
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Code committed to Git." -ForegroundColor Green
} else {
    Write-Host "- Working tree clean, nothing new to commit." -ForegroundColor Gray
}

Write-Host "Pushing to GitHub main..." -ForegroundColor Yellow
git push origin main

# 6. GitHub Release Publishing
Write-Host "[6/6] Publishing GitHub Release (v$Version)..." -ForegroundColor Yellow

$tag = "v$Version"
$releaseTitle = "PomoDo v$Version"

& gh release create $tag $distApk --title $releaseTitle --notes $Notes
if ($LASTEXITCODE -eq 0) {
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " SUCCESS: PomoDo v$Version released successfully!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host " Local Archive: $distApk ($apkSizeMB MB)" -ForegroundColor White
    Write-Host " GitHub Release: https://github.com/chonggao9/pomodo/releases/tag/$tag" -ForegroundColor Cyan
    Write-Host " Direct Download: https://github.com/chonggao9/pomodo/releases/download/$tag/PomoDo_v${Version}_Android.apk" -ForegroundColor Cyan
    Write-Host " In-App Update: Synced and active!" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
} else {
    Write-Warning "gh release create failed. Please check network or gh auth."
}
