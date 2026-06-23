@echo off
set DB_FILE=.\data\factpro.db
set BACKUP_DIR=.\backups

echo Available backups:
dir /b "%BACKUP_DIR%\*.db" 2>nul
if %errorlevel% neq 0 (
    echo No backups found.
    exit /b 1
)

set /p BACKUP=Enter backup filename (without path):
if exist "%BACKUP_DIR%\%BACKUP%" (
    copy "%BACKUP_DIR%\%BACKUP%" "%DB_FILE%"
    echo Restore concluido.
) else (
    echo Erro: Backup nao encontrado.
    exit /b 1
)
