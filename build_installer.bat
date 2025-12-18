@echo off
echo Building DentalTid Installer
echo.

if not exist "build\windows\x64\runner\Release\dentaltid.exe" (
    echo Error: App not built yet. Run 'flutter build windows --release' first.
    pause
    exit /b 1
)

echo Compiling x64 installer...
iscc installer_x64.iss

if %errorlevel% neq 0 (
    echo Error: Failed to compile x64 installer
    pause
    exit /b 1
)

echo.
echo x64 installer created: dist\dentaltid_x64_setup.exe
echo.

if exist "build\windows\x86\runner\Release\dentaltid.exe" (
    echo Compiling x86 installer...
    iscc installer_x86.iss

    if %errorlevel% neq 0 (
        echo Error: Failed to compile x86 installer
        pause
        exit /b 1
    )

    echo.
    echo x86 installer created: dist\dentaltid_x86_setup.exe
) else (
    echo x86 build not found. Run on x86 machine or use x86 tools to build x86 version.
)

echo.
echo Installation complete!
pause
