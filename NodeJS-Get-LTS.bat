@echo off

cd /d %~dp0

set HERE=%~dp0
set HERE_DS=%HERE:\=\\%

set BUSYBOX=%HERE%Utils\busybox.exe
set SZIP="%HERE%Utils\7za.exe"

:::::: NETWORK CHECK

%BUSYBOX% wget -q --user-agent="Mozilla" --spider https://nodejs.org

if "%ERRORLEVEL%" == "1" (
  echo Check Your Network Connection
  pause
  exit
)

::::::::::::::::::::

:::::: ARCH

if "%PROCESSOR_ARCHITECTURE%" == "x86" (
  set ARCH=x86
) else if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  set ARCH=x64
) else exit

:: set ARCH=x86
:: set ARCH=x64

::::::::::::::::::::

:::::: VERSION CHECK

set APP_EXE=App\node.exe
if not exist %APP_EXE% goto LATEST

for /f %%V in ('powershell -NoProfile -Command ^
  "(Get-Item %APP_EXE%).VersionInfo.FileVersion"') do (
    set CURRENT=%%V
)
echo Current: %CURRENT%

:LATEST

set LATEST_URL="https://nodejs.org"

for /f %%V in ('%BUSYBOX% wget -q -O- %LATEST_URL%
  ^| %BUSYBOX% grep -o ">v[0-9.]\+[0-9]"
  ^| %BUSYBOX% head -1
  ^| %BUSYBOX% cut -d "v" -f2') ^
do (set LATEST=%%V)
echo Latest: %LATEST%
echo:

if "%CURRENT%" == "%LATEST%" (
  echo You Have The Latest Version
  pause
  exit
) else goto GET

::::::::::::::::::::

:GET

:::::: GET LATEST VERSION

set NodeLTS="https://nodejs.org/dist/v%LATEST%/node-v%LATEST%-win-%ARCH%.zip"

if exist "tmp" rmdir "tmp" /s /q
mkdir "tmp"

%BUSYBOX% wget %NodeLTS% -O TMP\node-%LATEST%-%ARCH%.zip

::::::::::::::::::::

:::::: UNPACKING

echo:
echo Unpacking

%SZIP% x -aoa tmp\node-%LATEST%-%ARCH%.zip -o"tmp\" > NUL

robocopy /move /s tmp\node-v%LATEST%-win-%ARCH% App\ /NFL /NDL /NJH /NJS

rmdir "tmp" /s /q

::::::::::::::::::::

:::::: NPMRC

if not exist "App\etc" mkdir "App\etc"
echo cache = %HERE%Cache > "App\etc\npmrc"
echo globalconfig = %HERE%etc\npmrc >> "App\etc\npmrc"
echo globalignorefile = %HERE%etc\.npmignore >> "App\etc\npmrc"
echo init-module = %HERE%etc\.npm-init.js >> "App\etc\npmrc"
echo userconfig = %HERE%etc\.npmrc >> "App\etc\npmrc"

::::::::::::::::::::

:::::: PATH

set PathExist=1
set PathCheck="echo ";%PATH%;" | find /c /i ";%HERE%App;" "

for /f %%P in ('%PathCheck%') do set FindPath=%%P

if %PathExist% == %FindPath% (
  exit
)

set Key=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment

for /f "tokens=2*" %%a in ('reg.exe query "%Key%" /v Path^|Find "Path"') do set CurPath=%%~b
reg.exe add "%Key%" /v Path /t REG_EXPAND_SZ /d "%CurPath%;%HERE%App" /f

setx temp "%temp%"

::::::::::::::::::::

echo Done
pause
