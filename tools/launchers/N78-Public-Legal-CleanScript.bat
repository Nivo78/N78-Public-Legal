@echo off
setlocal EnableExtensions
title N78-Public-Legal cleanscript

set "PATH=C:\Program Files\PowerShell\7;C:\Program Files\PowerShell\7-preview;%PATH%"

set "PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if not exist "%PWSH%" set "PWSH=C:\Program Files\PowerShell\7-preview\pwsh.exe"
if not exist "%PWSH%" set "PWSH=powershell.exe"

set "REPO="
for %%P in (
    "C:\Users\Mike\Desktop\Nivo78\N78-Public-Legal"
    "%USERPROFILE%\Desktop\Nivo78\N78-Public-Legal"
) do (
    if exist "%%~P\README.md" if exist "%%~P\legal.css" (
        set "REPO=%%~P"
        goto :found_repo
    )
)

echo Could not find N78-Public-Legal repo.
pause
exit /b 1

:found_repo
set "CLEAN=%REPO%\tools\maintain\run-cleanscript.ps1"
if not exist "%CLEAN%" (
    echo Missing: %CLEAN%
    pause
    exit /b 1
)

cd /d "%REPO%"
"%PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%CLEAN%" %*
set "EXITCODE=%ERRORLEVEL%"
if %EXITCODE% neq 0 pause
endlocal & exit /b %EXITCODE%
