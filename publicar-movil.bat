@echo off
setlocal EnableDelayedExpansion

:: ---------------------------------------------------------------------------
:: publicar-movil.bat
:: Sube el APK de Chrysalis Movil como una release del repo publico.
:: Antes: en C:\proyectos\Chrysalis-Movil correr  npm run sync  y luego, en la
::        carpeta android,  .\gradlew.bat assembleDebug
:: Requisitos: GitHub CLI (gh) con sesion iniciada, y Node.js.
:: ---------------------------------------------------------------------------

set "REPO=SirSkeleton/chrysalis-releases"
set "MOVIL=C:\proyectos\Chrysalis-Movil"
set "APK=%MOVIL%\android\app\build\outputs\apk\debug\app-debug.apk"

echo.
echo  Chrysalis Movil -- Publicar release
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
if not exist "%APK%" (
    echo [ERROR] No existe %APK%
    echo         Genera primero el APK ^(npm run sync y gradlew assembleDebug^).
    pause & exit /b 1
)

:: Version = la de package.json de Chrysalis-Movil
set "VERSION="
for /f "delims=" %%v in ('node -p "require('C:/proyectos/Chrysalis-Movil/package.json').version"') do set "VERSION=%%v"
if "!VERSION!"=="" (
    echo [ERROR] No se pudo leer la version de package.json
    pause & exit /b 1
)
set "TAG=movil-v!VERSION!"
set "FILE=Chrysalis-!VERSION!.apk"

echo  APK     : %APK%
echo  Version : !VERSION!   ^(tag !TAG!^)
echo.
echo  Tipo de version:
echo    1 = Estable
echo    2 = Cambios menores
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

set "NOTES_FILE=%TEMP%\chrysalis_movil_notas.txt"
>"!NOTES_FILE!" echo(!NOTAS!

set "STAGE=%TEMP%\!FILE!"
copy /y "%APK%" "!STAGE!" >nul

echo.
echo  Publicando en %REPO% ...
gh release create "!TAG!" "!STAGE!" --repo "%REPO%" --title "Chrysalis Movil !VERSION!!SUFIJO!" --notes-file "!NOTES_FILE!" !FLAGS!
if !errorlevel! neq 0 (
    echo.
    echo [ERROR] No se pudo crear la release. Revisa el mensaje de arriba.
    pause & exit /b 1
)

del "!NOTES_FILE!" >nul 2>&1
del "!STAGE!" >nul 2>&1
echo.
echo  Listo. La pagina mostrara el APK en unos minutos.
echo  https://github.com/%REPO%/releases/tag/!TAG!
echo.
pause
