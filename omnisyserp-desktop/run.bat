@echo off
REM Script para executar a aplicacao OmnisysERP Desktop

echo ============================================
echo   OmnisysERP Desktop - Controlo de Assiduidade
echo ============================================
echo.

REM Verificar se o JAR existe
if not exist "target\omnisyserp-desktop-1.0.0.jar" (
    echo A aplicar a compilacao...
    call mvn clean package -DskipTests
    echo.
)

echo A iniciar a aplicacao...
echo.

java -jar target\omnisyserp-desktop-1.0.0.jar

pause
