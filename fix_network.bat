@echo off
set PORT=8080
echo ==========================================
echo DentalTid Network Fix Utility
echo ==========================================
echo This script will open port %PORT% in the Windows Firewall.
echo.

:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with Administrator privileges.
) else (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click this file and select "Run as Administrator".
    pause
    exit /b 1
)

echo Opening TCP Port %PORT% for LAN Synchronization...
netsh advfirewall firewall delete rule name="DentalTid LAN Sync" >nul 2>&1
netsh advfirewall firewall add rule name="DentalTid LAN Sync" dir=in action=allow protocol=TCP localport=%PORT% profile=private,public

if %errorLevel% == 0 (
    echo [SUCCESS] Port %PORT% is now open.
    echo You can now connect your Staff devices.
) else (
    echo [FAILED] Failed to open the port automatically.
)

echo.
echo Press any key to exit.
pause >nul