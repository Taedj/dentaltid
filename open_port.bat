@echo off
set PORT=%1
if "%PORT%"=="" set PORT=8080

echo Requesting Administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrator privileges confirmed.
) else (
    echo Failure: Current permissions inadequate.
    exit /b 1
)

echo Opening TCP Port %PORT% in Windows Firewall...
netsh advfirewall firewall add rule name="DentalTid LAN Sync" dir=in action=allow protocol=TCP localport=%PORT%

if %errorLevel% == 0 (
    echo Port %PORT% opened successfully.
) else (
    echo Failed to open port.
)
pause
