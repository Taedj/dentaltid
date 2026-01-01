@echo off
echo ==========================================
echo      TAEDJ AUTO SYSTEM V2 - SYNC
echo ==========================================

echo [1/3] Running Sync Engine...
node CONTROL_WEBSITE\sync.js
if %errorlevel% neq 0 (
    echo Error: Sync Engine failed.
    pause
    exit /b %errorlevel%
)

echo [2/3] Committing Project Changes (Spoke)...
git add CONTROL_WEBSITE\WEBSITE.md CONTROL_WEBSITE\screenshots\*
git commit -m "Auto-sync: Updated project configuration and content"
:: Uncomment the next line to enable automatic push
:: git push origin main

echo [3/3] Committing Website Changes (Hub)...
pushd "D:\work\Dev\Websites\My Website\Frontend"
git add "data\projects.json" "app\projects\*" "public\assets\projects\*"
git commit -m "Auto-sync: Updated projects registry and content from dentaltid"
:: Uncomment the next line to enable automatic push
:: git push origin main
popd

echo ==========================================
echo      SYNC COMPLETED SUCCESSFULLY
echo ==========================================
pause
