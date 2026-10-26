@echo off
setlocal EnableDelayedExpansion

:: ---------------------------------------------------------------------------
:: publicar-release.bat
:: Sube el ultimo instalador de Chrysalis como una release del repo publico.
:: Requisitos: GitHub CLI (gh) con sesion iniciada (gh auth login).
:: ---------------------------------------------------------------------------

set "REPO=SirSkeleton/chrysalis-releases"
set "RELEASE_DIR=C:\proyectos\chrysalis\desktop\release"

echo.
echo  Chrysalis -- Publicar release
echo.

where gh >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] No se encontro GitHub CLI ^(gh^). Instalalo desde https://cli.github.com
    pause & exit /b 1
)
gh auth status >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] gh no tiene sesion iniciada. Ejecuta: gh auth login
    pause & exit /b 1
)

if not exist "%RELEASE_DIR%" (
    echo [ERROR] No existe %RELEASE_DIR%
    echo         Genera primero el instalador con build.bat
    pause & exit /b 1
)

:: Instalador mas reciente
set "FILE="
for /f "delims=" %%f in ('dir /b /o-d "%RELEASE_DIR%\Chrysalis Setup *.exe" 2^>nul') do (
    set "FILE=%%f"
    goto :found
)
echo [ERROR] No se encontro "Chrysalis Setup X.Y.Z.exe" en %RELEASE_DIR%
pause & exit /b 1

:found
set "VERSION=!FILE:Chrysalis Setup =!"
set "VERSION=!VERSION:.exe=!"
set "TAG=v!VERSION!"

echo  Instalador : !FILE!
echo  Version    : !VERSION!   ^(tag !TAG!^)
echo.
echo  Tipo de version:
echo    1 = Estable          ^(salto de version mayor, ej. 0.4.0^)
echo    2 = Cambios menores  ^(ej. 0.4.1^)
echo    3 = Prueba           ^(se marca como pre-release^)
choice /c 123 /n /m "  Elige 1, 2 o 3: "
set "TIPO=!errorlevel!"

set "FLAGS="
set "SUFIJO="
if "!TIPO!"=="3" (
    set "FLAGS=--prerelease"
    set "SUFIJO= (prueba)"
)

echo.
set /p "NOTAS=  Que cambio en esta version? (una linea): "
if "!NOTAS!"=="" set "NOTAS=Version !VERSION!"

set "NOTES_FILE=%TEMP%\chrysalis_notas.txt"
>"!NOTES_FILE!" echo(!NOTAS!

:: Si existe latest.yml (para el futuro actualizador automatico), se sube tambien
set "EXTRAS="
if exist "%RELEASE_DIR%\latest.yml" set "EXTRAS="%RELEASE_DIR%\latest.yml""
if exist "%RELEASE_DIR%\!FILE!.blockmap" set "EXTRAS=!EXTRAS! "%RELEASE_DIR%\!FILE!.blockmap""

echo.
echo  Publicando en %REPO% ...
gh release create "!TAG!" "%RELEASE_DIR%\!FILE!" !EXTRAS! --repo "%REPO%" --title "Chrysalis !VERSION!!SUFIJO!" --notes-file "!NOTES_FILE!" !FLAGS!
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] No se pudo crear la release. Revisa el mensaje de arriba.
    pause & exit /b 1
)

del "!NOTES_FILE!" >nul 2>&1
echo.
echo  Listo. La pagina mostrara la nueva version en unos minutos.
echo  https://github.com/%REPO%/releases/tag/!TAG!
echo.
pause
