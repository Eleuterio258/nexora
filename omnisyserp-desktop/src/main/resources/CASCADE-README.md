# OpenCV Cascade File

Este diretório deve conter o arquivo `haarcascade_frontalface_default.xml` para detecção de faces.

## Como obter o arquivo

### Opção 1: Download direto
Baixe do repositório oficial do OpenCV:
https://raw.githubusercontent.com/opencv/opencv/master/data/haarcascades/haarcascade_frontalface_default.xml

### Opção 2: Usar o script de download
Execute o script PowerShell incluído:
```powershell
.\download-cascade.ps1
```

### Opção 3: Manual
1. Acesse: https://github.com/opencv/opencv/tree/master/data/haarcascades
2. Clique em `haarcascade_frontalface_default.xml`
3. Clique em "Raw"
4. Salve o arquivo neste diretório

## Nota
O arquivo é necessário para o funcionamento da detecção de faces na aplicação. Sem ele, a câmera funcionará mas sem detecção facial.
