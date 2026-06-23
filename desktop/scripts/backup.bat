@echo off
set BACKUP_DIR=.\backups
set DB_FILE=.\data\factpro.db
set DATE=%date:~-4%%date:~3,2%%date:~0,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set DATE=%DATE: =0%

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

if exist "%DB_FILE%" (
    copy "%DB_FILE%" "%BACKUP_DIR%\factpro_%DATE%.db"
    echo Backup concluido: factpro_%DATE%.db
) else (
    echo Erro: Base de dados nao encontrada em %DB_FILE%
    exit /b 1
)

forfiles /p "%BACKUP_DIR%" /m *.db /d -30 /c "cmd /c del @path" 2>nul
echo Backups antigos eliminados.
