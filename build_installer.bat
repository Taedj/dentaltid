@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   DentalTid 64-bit Release Builder
echo ========================================

set ISCC_PATH="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

:: 1. Clean previous builds
echo [1/3] Cleaning project...
call flutter clean
if %errorlevel% neq 0 (
    echo Error during flutter clean
    pause
    exit /b 1
)

:: 2. Build x64 (64-bit)
echo [2/3] Building Windows x64 Release...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo Error building x64 version
    pause
    exit /b 1
)

:: 3. Compile x64 Installer
echo [3/3] Compiling x64 Installer...
%ISCC_PATH% installer_x64.iss
if %errorlevel% neq 0 (
    echo Error compiling x64 installer
    pause
    exit /b 1
)

echo.
echo ========================================
echo   BUILD COMPLETE!
echo   Check the 'dist' folder for:
echo   - dentaltid_x64_setup.exe
echo ========================================
pause
