@echo off
cd /d "%~dp0"
set "OCT_GUI=octave.exe --gui"
where octave.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "OCT_GUI=octave.exe --gui"
    goto :RUN_GUI
)
if exist "C:\Program Files\GNU Octave\Octave-11.3.0\octave-launch.exe" (
    set "OCT_GUI=C:\Program Files\GNU Octave\Octave-11.3.0\octave-launch.exe"
    goto :RUN_GUI
)
for /d %%D in ("C:\Program Files\GNU Octave\Octave*") do (
    if exist "%%D\octave-launch.exe" (
        set "OCT_GUI=%%D\octave-launch.exe"
        goto :RUN_GUI
    )
    if exist "%%D\mingw64\bin\octave.exe" (
        set "OCT_GUI=%%D\mingw64\bin\octave.exe --gui"
        goto :RUN_GUI
    )
)
echo [AVISO] No se encontro GNU Octave GUI en el PATH ni en C:\Program Files\GNU Octave.
pause
exit /b 1

:RUN_GUI
echo Iniciando GNU Octave GUI...
start "" %OCT_GUI%
