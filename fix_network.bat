@echo off
:: Check for administrative privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo [ERROR] This script must be run as Administrator.
    echo.
    echo Please right-click fix_network.bat and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

echo =======================================================
echo DentalTid - Local Network Connection Fix
echo =======================================================
echo.
echo Adding firewall rule to allow port 8080 (TCP)...
echo.

:: Check if rule already exists to avoid duplicates
netsh advfirewall firewall show rule name="DentalTid Sync" >nul 2>&1
if %errorLevel% == 0 (
    echo Rule "DentalTid Sync" already exists. Updating...
    netsh advfirewall firewall delete rule name="DentalTid Sync"
)

netsh advfirewall firewall add rule name="DentalTid Sync" dir=in action=allow protocol=TCP localport=8080 description="Allows DentalTid staff devices to connect to this server."

if %errorLevel% == 0 (
    echo.
    echo [SUCCESS] Port 8080 is now open.
    echo.
    echo IMPORTANT:
    echo 1. Make sure both computers are on the same Wi-Fi/Network.
    echo 2. Use the IP address displayed in the App's Connection Settings.
    echo.
) else (
    echo.
    echo [ERROR] Failed to add the firewall rule.
    echo.
)

pause
