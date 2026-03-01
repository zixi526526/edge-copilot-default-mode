@echo off
echo ============================================
echo  Edge Copilot Smart Plus - Launcher
echo ============================================
echo.

REM Find Edge path
set "EDGE_PATH="
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_PATH=C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)

if "%EDGE_PATH%"=="" (
    echo [ERROR] Edge not found. Please edit this file and set EDGE_PATH manually.
    pause
    exit /b 1
)

echo [1/3] Closing running Edge instances...
taskkill /F /IM msedge.exe /T >nul 2>&1
timeout /t 2 /nobreak >nul

echo [2/3] Starting Edge with previous tabs and remote debugging port 9222...
start "" "%EDGE_PATH%" --restore-last-session --remote-debugging-port=9222

timeout /t 3 /nobreak >nul

echo [3/3] Starting background daemon...
echo.
echo Keep this window open. Close it to stop auto-switching.
echo Make sure Edge is fully closed before first run.
echo ============================================
echo.

powershell -ExecutionPolicy Bypass -Command "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; & ([scriptblock]::Create([System.IO.File]::ReadAllText('%~dp0copilot-smart-plus-daemon.ps1', [System.Text.Encoding]::UTF8)))"

pause
