@echo off
rem Desktop Apps launcher — N78-Public-Legal cleanscript
setlocal
set "REPO=C:\Users\Mike\Desktop\Nivo78\N78-Public-Legal"
set "LAUNCHER=%REPO%\tools\launchers\N78-Public-Legal-CleanScript.bat"
if not exist "%LAUNCHER%" (
 echo Could not find %LAUNCHER%
 echo Update REPO in this bat file if your N78-Public-Legal folder moved.
 pause
 exit /b 1
)
call "%LAUNCHER%" %*
set "ERR=%ERRORLEVEL%"
if %ERR% NEQ 0 pause
endlocal & exit /b %ERR%
