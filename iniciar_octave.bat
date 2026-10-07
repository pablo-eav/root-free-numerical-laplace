@echo off
cd /d "%~dp0"
set "OCT_EXEC=octave.exe"
where octave.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    goto :RUN_OCTAVE
)
if exist "C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave.exe" (
    set "OCT_EXEC=C:\Program Files\GNU Octave\Octave-11.3.0\mingw64\bin\octave.exe"
    goto :RUN_OCTAVE
)
for /d %%D in ("C:\Program Files\GNU Octave\Octave*") do (
    if exist "%%D\mingw64\bin\octave.exe" (
        set "OCT_EXEC=%%D\mingw64\bin\octave.exe"
        goto :RUN_OCTAVE
    )
)
echo [AVISO] No se encontro octave.exe en el PATH ni en C:\Program Files\GNU Octave.
echo Por favor agregue Octave a la variable PATH o inicie Octave manualmente ejecutando start_toolbox.
pause
exit /b 1

:RUN_OCTAVE
echo Iniciando GNU Octave con Root-Free Laplace Toolbox...
start "" "%OCT_EXEC%" --persist --eval "start_toolbox;"
