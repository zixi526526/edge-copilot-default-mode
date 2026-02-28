@echo off
chcp 65001 >nul
echo ============================================
echo  Edge Copilot Smart Plus - 启动脚本
echo ============================================
echo.

REM 寻找 Edge 的安装路径
set "EDGE_PATH="
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

if "%EDGE_PATH%"=="" (
    echo [错误] 未能在默认路径找到 Microsoft Edge，请手动编辑本脚本中的 EDGE_PATH。
    pause
    exit /b 1
)

REM 关闭已运行的 Edge 实例 (防止未开启调试端口)
echo [1/3] 正在关闭已运行的 Edge 浏览器...
taskkill /F /IM msedge.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

REM 启动 Edge (如果尚未运行) 并启用远程调试端口
echo [2/3] 正在启动 Edge 并恢复上次的标签页 (远程调试端口: 9222)...
start "" "%EDGE_PATH%" --restore-last-session --remote-debugging-port=9222

REM 等待 Edge 启动
timeout /t 3 /nobreak >nul

REM 启动后台注入脚本
echo [3/3] 正在启动后台注入脚本...
echo.
echo 提示: 此窗口将保持运行以持续监控 Copilot 侧边栏.
echo       关闭此窗口即可停止自动切换功能.
echo       首次使用请确认 Edge 已完全关闭后再运行此脚本.
echo ============================================
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0copilot-smart-plus-daemon.ps1"

pause
