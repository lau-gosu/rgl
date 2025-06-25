@echo off
setlocal

set SCRIPT_PATH=%~dp0enable-ssh.ps1

:: Check for admin rights
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo [ERROR] Please run this script as Administrator.
    pause
    exit /b 1
)

:: Run script and show all output directly
powershell.exe -NoExit -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
