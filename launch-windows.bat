@echo off
setlocal EnableDelayedExpansion
title LUMINA CITY - Offline Launcher

cd /d "%~dp0"

echo ================================================================
echo   LUMINA CITY - Autonomous Intelligent City Showcase
echo   Offline Local Launcher
echo ================================================================
echo.

:: 1. Verify if 'dist' folder exists. If not, inform user.
if not exist "dist\index.html" (
    echo [!] Production folder "dist" is missing.
    echo Attempting to build project now...
    echo.
)

:: 2. Test if Node.js is installed and functional
node -v >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Node.js is ready.
    if not exist "dist\index.html" (
        if not exist "node_modules" (
            echo Installing dependencies (npm install)...
            call npm install
        )
        echo Building production assets (npm run build)...
        call npm run build
    )
    echo Starting zero-dependency offline server...
    echo.
    node launch.js
    goto :finished
)

:: 3. Node.js not detected -> Try built-in Windows PowerShell HTTP Server
echo [i] Node.js not found in PATH.
echo Checking for native Windows PowerShell server...
powershell -Command "$PSVersionTable.PSVersion.Major" >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Windows PowerShell detected.
    echo Launching native zero-dependency HTTP server...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launch-powershell.ps1"
    goto :finished
)

:: 4. Fallback to Python if available
python --version >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo [OK] Python detected. Using Python HTTP server...
    start "" "http://localhost:8080"
    python -m http.server 8080 --directory dist
    goto :finished
)

echo.
echo ================================================================
echo [X] Unable to start server automatically.
echo.
echo Possible solutions:
echo 1. Install Node.js from https://nodejs.org/ (Recommended)
echo 2. Or right-click "launch-powershell.ps1" and select "Run with PowerShell"
echo ================================================================
echo.

:finished
echo.
echo Server has stopped.
pause
