@echo off
setlocal
cd "%~dp0"

set START_MODE=%1
call Make-Settings.bat
rem echo on

cd %BASE_DIR%
pushd asm
call :assemble %RELEASE%-Loader
if ERRORLEVEL 1 exit /b

call :assemble %RELEASE%
if ERRORLEVEL 1 exit /b
popd

set COMPRESS_ADDRESS=$2000
set SOURCE_DIR=%BASE_DIR%\asm
set TARGET_DIR=%BASE_DIR%\site\%RELEASE_LOWERCASE%
if not exist %TARGET_DIR% mkdir %TARGET_DIR%

rem See https://bitbucket.org/magli143/exomizer/wiki/Home.
%EXOMIZER% sfx %COMPRESS_ADDRESS% %SOURCE_DIR%\%TARGET_FILE% -t 168 -o %SOURCE_DIR%\%TARGET_FILE% -x "stx $d017"
if ERRORLEVEL 1 goto :exomizer_error
if NOT ERRORLEVEL 0 goto :exomizer_error

copy /b  /b %SOURCE_DIR%\%RELEASE%-Loader.xex+%SOURCE_DIR%\%RELEASE%.xex %TARGET_FILE%
if ERRORLEVEL 1 goto :other_error

echo Creating disk image.
set ATR=%RELEASE%.atr
copy %TARGET_FILE% atr\files\AUTORUN.AR0
atr\hias\dir2atr.exe -m -b MyDos4534 %ATR% atr\files
if ERRORLEVEL 1 goto :dir2atr_error
echo Done.

start %ATR%

goto :eof

:assemble
set SOURCE_FILE=%1.asm
set TARGET_FILE=%1.xex
set OPTIONS=%2

%MADS% -s %SOURCE_FILE% -o:%TARGET_FILE% %OPTIONS%
if ERRORLEVEL 1 goto :mads_error
goto :eof


:mads_error
echo ERROR: MADS compilation errors occurred. Check error messages above.
exit /b

:exomizer_error
echo ERROR: Packer errors occurred. Check error messages above.
exit /b

:other_error
echo ERROR: Check error messages above.
exit /b

:dir2atr_error
echo ERROR: DIR2ATR errors occurred. Check error messages above.
exit /b