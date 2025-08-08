@echo off
echo Running version update script...
powershell -ExecutionPolicy Bypass -File update_version.ps1
if %ERRORLEVEL% EQU 0 (
    echo Version update completed successfully!
) else (
    echo Version update failed!
)
pause