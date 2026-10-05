@echo off
chcp 65001 >nul 2>&1
title AppData 深度安全清理
setlocal enabledelayedexpansion

:: ============================================================
::  AppData 深度安全清理
::  原则：只清理可重建的缓存/日志/临时数据，绝不触碰用户数据
:: ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [错误] 请右键选择「以管理员身份运行」！
    echo.
    pause
    exit /b 1
)

cls
echo ================================================================
echo    AppData 深度安全清理工具
echo ================================================================
echo.
echo   [清理范围]
echo     - 临时文件 / 错误报告 / 崩溃转储 / 诊断数据
echo     - 资源管理器缩略图与图标缓存
echo     - 显卡着色器缓存 (D3D / NVIDIA / AMD / Intel)
echo     - 浏览器缓存 (Chrome / Edge / Brave / Firefox 等)
echo     - 开发者包缓存 (pip / npm / NuGet / Yarn)
echo     - 软件日志 (OneDrive / Office)
echo.
echo   [绝对不碰]
echo     - %%APPDATA%% (Roaming) 所有配置与账号
echo     - 聊天记录 / 书签 / 登录状态 / 游戏存档
echo     - LocalLow / Packages\LocalState
echo.
echo   建议: 先关闭浏览器和大型软件，效果最佳。
echo         正在被占用的文件会被自动跳过，不会报错。
echo.
set /p CONFIRM=确认开始清理？(Y/N):
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo  已取消。
    pause
    exit /b 0
)

echo.
echo ----------------------------------------------------------------
echo  正在清理...
echo ----------------------------------------------------------------

rem ============ 1. 系统临时与缓存 ============
call :Clean "%LOCALAPPDATA%\Temp"                                        "用户临时文件"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\INetCache"                 "IE/Edge 旧版网页缓存"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\Temporary Internet Files"  "Temporary Internet Files"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\AppCache"                  "Windows 应用缓存"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\Caches"                    "Windows 系统缓存"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue"           "错误报告队列"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive"         "错误报告存档"
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\WER\Temp"                  "错误报告临时"
call :Clean "%LOCALAPPDATA%\Microsoft\Terminal Server Client\Cache"      "远程桌面缓存"
call :Clean "%LOCALAPPDATA%\ElevatedDiagnostics"                         "诊断数据"
call :Clean "%LOCALAPPDATA%\CrashDumps"                                  "崩溃转储文件"

rem ============ 2. 资源管理器缩略图/图标缓存 ============
call :Clean "%LOCALAPPDATA%\Microsoft\Windows\Explorer"                  "缩略图/图标缓存"

rem ============ 3. 显卡着色器缓存 ============
call :Clean "%LOCALAPPDATA%\D3DSCache"                                   "DirectX 着色器缓存"
call :Clean "%LOCALAPPDATA%\NVIDIA\DXCache"                              "NVIDIA DX 着色器缓存"
call :Clean "%LOCALAPPDATA%\NVIDIA\GLCache"                              "NVIDIA GL 着色器缓存"
call :Clean "%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache"                 "NVIDIA 驱动缓存"
call :Clean "%LOCALAPPDATA%\AMD\DxCache"                                 "AMD DX 着色器缓存"
call :Clean "%LOCALAPPDATA%\AMD\DxcCache"                                "AMD DXC 着色器缓存"
call :Clean "%LOCALAPPDATA%\AMD\GLCache"                                 "AMD GL 着色器缓存"
call :Clean "%LOCALAPPDATA%\Intel\ShaderCache"                           "Intel 着色器缓存"

rem ============ 4. 开发者包缓存 ============
call :Clean "%LOCALAPPDATA%\pip\cache"                                   "pip 包缓存"
call :Clean "%LOCALAPPDATA%\npm-cache"                                   "npm 包缓存"
call :Clean "%LOCALAPPDATA%\NuGet\v3-cache"                              "NuGet 包缓存"
call :Clean "%LOCALAPPDATA%\Yarn\Cache"                                  "Yarn 包缓存"

rem ============ 5. 浏览器缓存 ============
call :CleanBrowser "%LOCALAPPDATA%\Google\Chrome\User Data"               "Chrome"
call :CleanBrowser "%LOCALAPPDATA%\Microsoft\Edge\User Data"              "Edge"
call :CleanBrowser "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data" "Brave"
call :CleanBrowser "%LOCALAPPDATA%\Vivaldi\User Data"                     "Vivaldi"
call :CleanBrowser "%LOCALAPPDATA%\Opera Software\Opera Stable"           "Opera"
call :CleanFirefox

rem ============ 6. 软件日志与缓存 ============
call :Clean "%LOCALAPPDATA%\Microsoft\OneDrive\logs"                     "OneDrive 日志"
call :Clean "%LOCALAPPDATA%\Microsoft\Office\16.0\OfficeFileCache"       "Office 文件缓存"
call :Clean "%LOCALAPPDATA%\Microsoft\Office\16.0\Wef"                   "Office 漫游缓存"

echo.
echo ================================================================
echo    清理完成！
echo ================================================================
echo.
echo    提示: 缩略图/图标缓存需要重启资源管理器或重启电脑后重建。
echo          如需立即重建，可在 CMD 中执行：
echo            taskkill /f /im explorer.exe ^& start explorer.exe
echo.
pause
exit /b 0


rem ================================================================
rem  子程序: Clean
rem    清空目录内容, 保留目录本身
rem    %1 = 目标路径   %2 = 显示名称
rem ================================================================
:Clean
set "TGT=%~1"
set "NME=%~2"
if not exist "%TGT%\" (
    echo   [跳过] %NME%
    goto :EOF
)
echo   [清理] %NME%
del /f /s /q /a "%TGT%\*" >nul 2>&1
for /d %%D in ("%TGT%\*") do rd /s /q "%%~D" >nul 2>&1
goto :EOF


rem ================================================================
rem  子程序: CleanBrowser
rem    清理 Chromium 系浏览器缓存 (仅 Cache 类目录, 不碰用户数据)
rem    %1 = User Data 路径   %2 = 浏览器名
rem ================================================================
:CleanBrowser
set "UD=%~1"
set "BN=%~2"
if not exist "%UD%\" goto :EOF
call :Clean "%UD%\ShaderCache"         "%BN% ShaderCache"
call :Clean "%UD%\GrShaderCache"       "%BN% GrShaderCache"
call :Clean "%UD%\GraphiteDawnCache"   "%BN% GraphiteDawnCache"
for /d %%P in ("%UD%\*") do (
    call :Clean "%%~fP\Cache"                       "%BN% 网页缓存 [%%~nxP]"
    call :Clean "%%~fP\Code Cache"                  "%BN% 代码缓存 [%%~nxP]"
    call :Clean "%%~fP\GPUCache"                    "%BN% GPU 缓存 [%%~nxP]"
    call :Clean "%%~fP\Service Worker\CacheStorage" "%BN% SW 缓存 [%%~nxP]"
    call :Clean "%%~fP\Service Worker\ScriptCache"  "%BN% SW 脚本缓存 [%%~nxP]"
)
goto :EOF


rem ================================================================
rem  子程序: CleanFirefox
rem    仅清理 Local 下的 Firefox 缓存, Roaming 中的配置不动
rem ================================================================
:CleanFirefox
set "FFROOT=%LOCALAPPDATA%\Mozilla\Firefox\Profiles"
if not exist "%FFROOT%\" goto :EOF
for /d %%P in ("%FFROOT%\*") do (
    call :Clean "%%~fP\cache2"       "Firefox 网页缓存 [%%~nxP]"
    call :Clean "%%~fP\startupCache" "Firefox 启动缓存 [%%~nxP]"
    call :Clean "%%~fP\shader-cache" "Firefox 着色器缓存 [%%~nxP]"
    call :Clean "%%~fP\thumbnails"   "Firefox 缩略图 [%%~nxP]"
)
goto :EOF