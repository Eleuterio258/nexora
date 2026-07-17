# Script para download do OpenCV Cascade File
$url = "https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_frontalface_default.xml"
$output = "$PSScriptRoot\haarcascade_frontalface_default.xml"

Write-Host "A descarregar OpenCV cascade file..."
try {
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Host "Download concluido com sucesso: $output" -ForegroundColor Green
} catch {
    Write-Host "Erro no download: $_" -ForegroundColor Red
    exit 1
}
