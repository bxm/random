@echo off
setlocal

set time=%~2
set time=%time: =0%

set stamp.file=%temp%\%~n0.stamp

if /i "%~1" EQU "start" call :make.stamp
if /i "%~1" EQU "stop"  call :read.stamp stop
if /i "%~1" EQU "lap"   call :read.stamp lap
if    "%~1" EQU ""      call :status

endlocal
goto :EOF

:status

 if exist "%stamp.file%" (
	 if /i "%~1" NEQ "/q" echo:Timer is active.
	 exit /b 0
 )

 echo:Timer is not active.
 exit /b 1

:make.stamp

 if exist "%stamp.file%" call :read.stamp stop
 set start.time=%time%

 (echo:%start.time%) > "%stamp.file%"
 echo:Timer started %start.time%
 goto :EOF

:read.stamp

 call :status /q
 if errorlevel 1 goto :EOF
 set stop.time=%time%
 set /p start.time=< "%stamp.file%"

 echo:Timer started %start.time%
 echo:Timer %1ped %stop.time%

 if %1 EQU stop del "%stamp.file%"

 call :calc.time.code %start.time%
 set start.time.code=%errorlevel%

 call :calc.time.code %stop.time%
 set stop.time.code=%errorlevel%

 set /a diff.time.code=stop.time.code - start.time.code

 if %diff.time.code% LSS 0 set /a diff.time.code+=(24 * 60 * 60 * 100)

 setlocal

 set /a hs=diff.time.code %% 100
 set /a diff.time.code/=100
 set /a ss=diff.time.code %% 60
 set /a diff.time.code/=60
 set /a mm=diff.time.code %% 60
 set /a diff.time.code/=60
 set /a hh=diff.time.code

 set hh=0%hh%
 set mm=0%mm%
 set ss=0%ss%
 set hs=0%hs%

 endlocal & set diff.time=%hh:~-2%:%mm:~-2%:%ss:~-2%.%hs:~-2%

 echo %diff.time.code% hundredths of a second
 echo %diff.time%

 goto :EOF

:calc.time.code

 setlocal
 for /f "usebackq tokens=1,2,3,4 delims=:." %%a in ('%1') do (
    set hh=%%a
    set mm=%%b
    set ss=%%c
    set hs=%%d
 )

 set /a hh=((%hh:~0,1% * 10) + %hh:~1,1%) * 60 * 60 * 100
 set /a mm=((%mm:~0,1% * 10) + %mm:~1,1%) * 60 * 100
 set /a ss=((%ss:~0,1% * 10) + %ss:~1,1%) * 100
 set /a hs=((%hs:~0,1% * 10) + %hs:~1,1%)

 set /a time.code=hh + mm + ss + hs
 endlocal & exit /b %time.code%
