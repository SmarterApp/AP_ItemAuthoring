@echo off

REM
REM Collect the command line args
REM

set DROP_FIRST=%0
set WL_ENV=%1
shift
set BUILD_PATH=%1
shift

set CMD_LINE_ARGS=
:setArgs
if ""%1""=="""" goto doneSetArgs
set CMD_LINE_ARGS=%CMD_LINE_ARGS% %1
shift
goto setArgs
:doneSetArgs

call %WL_ENV%
ant -f %BUILD_PATH%\bin\wl-build.xml %CMD_LINE_ARGS%
