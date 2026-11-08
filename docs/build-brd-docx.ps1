param(
    [string]$SourceName = 'brd-nexora-erp.md',
    [string]$TargetName = 'BRD-Nexora-ERP.docx'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$source = Join-Path $PSScriptRoot $SourceName
$target = Join-Path $PSScriptRoot $TargetName
$utf8 = New-Object System.Text.UTF8Encoding($false)
function Esc([string]$s) { [System.Security.SecurityElement]::Escape($s) }
function Para([string]$text, [string]$style = 'Normal') {
    '<w:p><w:pPr><w:pStyle w:val="' + $style + '"/></w:pPr><w:r><w:t xml:space="preserve">' + (Esc $text) + '</w:t></w:r></w:p>'
}
function Table([object[]]$lines) {
    $rows = @($lines | Where-Object { $_ -notmatch '^\|[- :|]+\|$' } | ForEach-Object {
        ,@($_.Trim().Trim('|').Split('|') | ForEach-Object { $_.Trim() })
    })
    $count = $rows[0].Count
    if ($count -eq 2) { $widths = @(2700,6938) } else { $widths = @(1550,4044,4044) }
    $b = New-Object System.Text.StringBuilder
    [void]$b.Append('<w:tbl><w:tblPr><w:tblW w:w="9638" w:type="dxa"/><w:tblLayout w:type="fixed"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="D8E0E8"/><w:bottom w:val="single" w:sz="4" w:color="D8E0E8"/><w:insideH w:val="single" w:sz="4" w:color="D8E0E8"/></w:tblBorders><w:tblCellMar><w:top w:w="95" w:type="dxa"/><w:left w:w="120" w:type="dxa"/><w:bottom w:w="95" w:type="dxa"/><w:right w:w="120" w:type="dxa"/></w:tblCellMar></w:tblPr><w:tblGrid>')
    foreach ($width in $widths) { [void]$b.Append('<w:gridCol w:w="' + $width + '"/>') }
    [void]$b.Append('</w:tblGrid>')
    for ($j = 0; $j -lt $rows.Count; $j++) {
        $head = $j -eq 0
        [void]$b.Append('<w:tr><w:trPr><w:cantSplit/>')
        if ($head) { [void]$b.Append('<w:tblHeader/>') }
        [void]$b.Append('</w:trPr>')
        for ($k = 0; $k -lt $count; $k++) {
            $fill = if ($head) { '17354D' } elseif ($j % 2 -eq 0) { 'F3F6F8' } else { 'FFFFFF' }
            $format = if ($head) { '<w:b/><w:color w:val="FFFFFF"/>' } else { '<w:color w:val="203140"/>' }
            [void]$b.Append('<w:tc><w:tcPr><w:tcW w:w="' + $widths[$k] + '" w:type="dxa"/><w:shd w:fill="' + $fill + '"/><w:vAlign w:val="center"/></w:tcPr><w:p><w:pPr><w:pStyle w:val="TableText"/></w:pPr><w:r><w:rPr>' + $format + '</w:rPr><w:t xml:space="preserve">' + (Esc $rows[$j][$k]) + '</w:t></w:r></w:p></w:tc>')
        }
        [void]$b.Append('</w:tr>')
    }
    [void]$b.Append('</w:tbl><w:p><w:pPr><w:spacing w:after="90"/></w:pPr></w:p>')
    $b.ToString()
}
$body = New-Object System.Text.StringBuilder
$lines = [System.IO.File]::ReadAllLines($source, [System.Text.Encoding]::UTF8)
for ($i = 0; $i -lt $lines.Length; $i++) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line.StartsWith('|')) {
        $batch = New-Object System.Collections.Generic.List[string]
        while ($i -lt $lines.Length -and $lines[$i].StartsWith('|')) { $batch.Add($lines[$i]); $i++ }
        $i--
        [void]$body.Append((Table $batch.ToArray()))
    } elseif ($line.StartsWith('# ')) {
        [void]$body.Append((Para 'E258TECH  /  GESTÃO INTEGRADA' 'Eyebrow'))
        [void]$body.Append((Para $line.Substring(2) 'Title'))
    } elseif ($line.StartsWith('## Documento')) {
        [void]$body.Append((Para $line.Substring(3) 'Subtitle'))
    } elseif ($line.StartsWith('## ')) {
        if ($line.StartsWith('## 1. ')) { [void]$body.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>') }
        [void]$body.Append((Para $line.Substring(3) 'Heading1'))
    } elseif ($line.StartsWith('### ')) {
        [void]$body.Append((Para $line.Substring(4) 'Heading2'))
    } else {
        [void]$body.Append((Para $line))
    }
}
$ns = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"'
$docXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document ' + $ns + '><w:body>' + $body.ToString() + '<w:sectPr><w:headerReference w:type="default" r:id="rHeader"/><w:footerReference w:type="default" r:id="rFooter"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="500" w:footer="500"/></w:sectPr></w:body></w:document>'
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/><w:sz w:val="21"/><w:color w:val="203140"/><w:lang w:val="pt-PT"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="110" w:line="270" w:lineRule="auto"/><w:widowControl/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="1450" w:after="240"/><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val="64"/><w:color w:val="17354D"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Subtitle"><w:name w:val="Subtitle"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="440"/><w:keepNext/></w:pPr><w:rPr><w:sz w:val="30"/><w:color w:val="407B88"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Eyebrow"><w:name w:val="Eyebrow"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:before="450" w:after="140"/><w:keepNext/></w:pPr><w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="407B88"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="260" w:after="150"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="29"/><w:color w:val="17354D"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="190" w:after="110"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="23"/><w:color w:val="407B88"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="TableText"><w:name w:val="Table Text"/><w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="20" w:line="250" w:lineRule="auto"/></w:pPr><w:rPr><w:sz w:val="19"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Header"><w:name w:val="Header"/><w:basedOn w:val="Normal"/><w:rPr><w:sz w:val="17"/><w:color w:val="607080"/></w:rPr></w:style>
</w:styles>
'@
$files = @{
    '[Content_Types].xml' = '<?xml version="1.0" encoding="UTF-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>'
    '_rels/.rels' = '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rDoc" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rCore" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>'
    'word/document.xml' = $docXml
    'word/styles.xml' = $styles
    'word/_rels/document.xml.rels' = '<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rHeader" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/><Relationship Id="rFooter" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/><Relationship Id="rSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/></Relationships>'
    'word/header1.xml' = '<w:hdr ' + $ns + '>' + (Para 'NEXORA ERP   |   REQUISITOS DE NEGÓCIO   |   v0.1 — PROPOSTA' 'Header') + '</w:hdr>'
    'word/footer1.xml' = '<w:ftr ' + $ns + '><w:p><w:pPr><w:pStyle w:val="Header"/><w:jc w:val="right"/></w:pPr><w:r><w:t>14/10/2026  |  Página </w:t></w:r><w:fldSimple w:instr="PAGE"><w:r><w:t>1</w:t></w:r></w:fldSimple></w:p></w:ftr>'
    'word/settings.xml' = '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:updateFields w:val="true"/><w:defaultTabStop w:val="708"/></w:settings>'
    'docProps/core.xml' = '<?xml version="1.0" encoding="UTF-8"?><cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>BRD — Nexora ERP</dc:title><dc:subject>Documento de requisitos de negócio</dc:subject><dc:creator>E258TECH</dc:creator><cp:keywords>BRD, Nexora ERP, requisitos de negócio</cp:keywords><dc:description>Versão 0.1 para validação. 14/10/2026.</dc:description></cp:coreProperties>'
}
$stream = [System.IO.File]::Open($target,[System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($stream,[System.IO.Compression.ZipArchiveMode]::Create,$false)
try {
    foreach ($name in $files.Keys) {
        [xml]$check = $files[$name]
        $entry = $zip.CreateEntry($name)
        $writer = New-Object System.IO.StreamWriter($entry.Open(),$utf8)
        try { $writer.Write($files[$name]) } finally { $writer.Dispose() }
    }
} finally { $zip.Dispose(); $stream.Dispose() }
Write-Output $target
Write-Output ('XML parts checked: ' + $files.Count)
