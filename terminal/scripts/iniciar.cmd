@echo off
setlocal
cd /d "%~dp0.."
if exist "target\assiduidade-terminal-1.0.0.jar" (
  java -jar "target\assiduidade-terminal-1.0.0.jar"
) else (
  mvn compile exec:java
)
endlocal
