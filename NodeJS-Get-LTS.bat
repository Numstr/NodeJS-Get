@echo off
SetLocal EnableExtensions EnableDelayedExpansion

cd /d %~dp0

set CurFolder=%~dp0

set CURL="%CurFolder%\Utils\curl.exe"
set GREP="%CurFolder%\Utils\grep.exe"
set TAR="%CurFolder%\Utils\tar.exe"
set ZCAT="%CurFolder%\Utils\zcat.exe"

set NodeVers=
set "LastNodeVers=%CURL% -s -k -r 15-16 https://nodejs.org/download/release/index.json"
for /f %%V in ('%LastNodeVers%') do (set NodeVers=%%V)

set NpmVers=
set "LastNpmVers=%CURL% -s -k -r 145-150 https://registry.npmjs.org/npm"
for /f %%V in ('%LastNpmVers%') do (set NpmVers=%%V)

set PathExist=1
set PathCheck="echo ";%PATH%;" | find /C /I ";%CurFolder%App;" "

::::::::::::::::::::

%CURL% -Is www.google.com | %GREP% -q "200 OK"

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

set /a NodeLTS=%NodeVers% / 2 * 2

if %NodeLTS% == %NodeVers% (
  set /a NodeLTS=%NodeVers% - 2
) else (
  set /a NodeLTS=%NodeVers% - 3
)

if "%PROCESSOR_ARCHITECTURE%" == "AMD64" (
  echo   Get Latest NodeJS LTS x64
  %CURL% -#k https://nodejs.org/download/release/latest-v%NodeLTS%.x/win-x64/node.exe -o "App\node.exe"
) else if "%PROCESSOR_ARCHITECTURE%" == "x86" (
  echo   Get Latest NodeJS LTS x86
  %CURL% -#k https://nodejs.org/download/release/latest-v%NodeLTS%.x/win-x86/node.exe -o "App\node.exe"
) else exit

::::::::::::::::::::

:::::: NPM

if exist "tmp" (
  rmdir "tmp" /S /Q
) else (
  mkdir "tmp"
)

echo   Get Latest NPM
%CURL% -#k https://registry.npmjs.org/npm/-/npm-%NpmVers%.tgz -o "tmp\npm-%NpmVers%.tgz"

if exist "App\node_modules" (
  rmdir "App\node_modules\npm" /S /Q
) else (
  mkdir "App\node_modules"
)

%ZCAT% "tmp\npm-%NpmVers%.tgz" | %TAR% -C "tmp" -x
rename "tmp\package" "npm"

robocopy /S tmp\npm App\node_modules\npm
robocopy /S App\node_modules\npm\bin App\ npm npm.cmd npx npx.cmd

rmdir "tmp" /S /Q

::::::::::::::::::::

mkdir "App\etc"
echo cache = %CurFolder%Cache > "App\etc\npmrc"
echo globalconfig = %CurFolder%etc\npmrc >> "App\etc\npmrc"
echo globalignorefile = %CurFolder%etc\.npmignore >> "App\etc\npmrc"
echo init-module = %CurFolder%etc\.npm-init.js >> "App\etc\npmrc"
echo userconfig = %CurFolder%etc\npmrc >> "App\etc\npmrc"

:::::: PATH

for /f %%C in ('%PathCheck%') do set FindPath=%%C

if %PathExist% == %FindPath% (
  exit
)

set Key=HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment

for /f "tokens=2*" %%a In ('reg.exe query "%Key%" /v Path^|Find "Path"') do set CurPath=%%~b
reg.exe add "%Key%" /v Path /t REG_EXPAND_SZ /d "%CurPath%;%CurFolder%App" /f

setx temp "%temp%"

::::::::::::::::::::
