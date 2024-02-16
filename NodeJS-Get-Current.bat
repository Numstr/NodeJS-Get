@echo off

cd /d %~dp0

set HERE=%~dp0
set HERE_DS=%HERE:\=\\%

set BUSYBOX="%HERE%Utils\busybox.exe"
set CURL="%HERE%Utils\curl.exe"

set CurNodeHash="certUtil -hashfile %HERE%App\node.exe SHA256 | findstr ^[0-9a-f]$"

:::::: NETWORK CHECK

%BUSYBOX% wget -q --user-agent="Mozilla" --spider https://google.com

if "%ERRORLEVEL%" == "1" (
  echo Check Your Network Connection
  pause
  exit
)

::::::::::::::::::::

:::::: NODE

if not exist "App" (
  mkdir "App"
)

if not exist "App/node.exe" (
  GOTO N1
) else GOTO N0

:N0

if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  set LastNodeHash64="%CURL% -s -k https://nodejs.org/download/release/latest/SHASUMS256.txt | %BUSYBOX% grep "win-x64/node.exe" "
) else if "%PROCESSOR_ARCHITECTURE%" == "x86" (
  set LastNodeHash86="%CURL% -s -k https://nodejs.org/download/release/latest/SHASUMS256.txt | %BUSYBOX% grep "win-x86/node.exe" "
) else exit

for /f %%H in ('%CurNodeHash%') do Set CurHash=%%H
for /f %%H in ('%LastNodeHash64%') do Set LastHash=%%H
for /f %%H in ('%LastNodeHash86%') do Set LastHash=%%H

if %CurHash% == %LastHash% (
  GOTO NPM
) else GOTO N1

:N1

if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  echo   Get Latest NodeJS Current x64
  %CURL% -# -k https://nodejs.org/download/release/latest/win-x64/node.exe -o "App\node.exe"
) else if "%PROCESSOR_ARCHITECTURE%" == "x86" (
  echo   Get Latest NodeJS Current x86
  %CURL% -# -k https://nodejs.org/download/release/latest-v17.x/win-x86/node.exe -o "App\node.exe"
) else exit

::::::::::::::::::::

:::::: NPM

:NPM

set NPM_URL="https://github.com/npm/cli/releases/latest"

%BUSYBOX% wget -q -O - %NPM_URL% | %BUSYBOX% grep -o tag/v[0-9.]\+[0-9] | %BUSYBOX% cut -d "v" -f2 > latest.txt
for /f %%V in ('more latest.txt') do (set NpmVers=%%V)

if exist "latest.txt" del "latest.txt" > NUL

if exist "tmp" rmdir "tmp" /s /q
mkdir "tmp"

echo   Get Latest NPM
%CURL% -# -k https://registry.npmjs.org/npm/-/npm-%NpmVers%.tgz -o "tmp\npm-%NpmVers%.tgz"

if exist "App\node_modules" (
  rmdir "App\node_modules\npm" /s /q
) else (
  mkdir "App\node_modules"
)

%BUSYBOX% zcat "tmp\npm-%NpmVers%.tgz" | %BUSYBOX% tar -C "tmp" -xm

robocopy /move /s tmp\package App\node_modules\npm /NFL /NDL /NJH /NJS
robocopy /s App\node_modules\npm\bin App\ npm npm.cmd npx npx.cmd /NFL /NDL /NJH /NJS

rmdir "tmp" /s /q

::::::::::::::::::::

:::::: NPMRC

if not exist "App\etc" mkdir "App\etc"
echo cache = %HERE%Cache > "App\etc\npmrc"
echo globalconfig = %HERE%etc\npmrc >> "App\etc\npmrc"
echo globalignorefile = %HERE%etc\.npmignore >> "App\etc\npmrc"
echo init-module = %HERE%etc\.npm-init.js >> "App\etc\npmrc"
echo userconfig = %HERE%etc\npmrc >> "App\etc\npmrc"

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
