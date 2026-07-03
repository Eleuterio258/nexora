$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$outDir = Join-Path $workspace "docs"
$buildDir = Join-Path $env:TEMP ("carta_ipcta_docx_" + [guid]::NewGuid().ToString("N"))
$docxPath = Join-Path $outDir "carta_ipcta_gestao_escolar_e258tech.docx"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "docProps") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "word") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "word\_rels") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "word\theme") | Out-Null

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function U {
    param([Parameter(Mandatory = $true)][string]$Text)
    return [regex]::Replace($Text, "\\u([0-9A-Fa-f]{4})", {
        param($Match)
        return [string][char][Convert]::ToInt32($Match.Groups[1].Value, 16)
    })
}

$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>
  <Override PartName="/word/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
</Types>
'@

$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>
'@

$documentRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/>
</Relationships>
'@

$core = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Carta de Proposta - Sistema de Gest&#x00E3;o Escolar</dc:title>
  <dc:creator>e258tech.tech</dc:creator>
  <cp:lastModifiedBy>e258tech.tech</cp:lastModifiedBy>
  <dcterms:created xsi:type="dcterms:W3CDTF">2026-06-29T00:00:00Z</dcterms:created>
  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-06-29T00:00:00Z</dcterms:modified>
</cp:coreProperties>
'@

$app = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
  <Application>Microsoft Word</Application>
  <DocSecurity>0</DocSecurity>
  <ScaleCrop>false</ScaleCrop>
  <Company>e258tech.tech</Company>
  <LinksUpToDate>false</LinksUpToDate>
  <SharedDoc>false</SharedDoc>
  <HyperlinksChanged>false</HyperlinksChanged>
  <AppVersion>16.0000</AppVersion>
</Properties>
'@

$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Aptos" w:hAnsi="Aptos"/>
        <w:sz w:val="22"/>
        <w:color w:val="1F2937"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="160" w:line="276" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="80" w:after="260"/>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:rPr>
      <w:b/>
      <w:color w:val="0F766E"/>
      <w:sz w:val="32"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Meta">
    <w:name w:val="Meta"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:sz w:val="20"/>
      <w:color w:val="4B5563"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Subject">
    <w:name w:val="Subject"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="220" w:after="220"/>
    </w:pPr>
    <w:rPr>
      <w:b/>
      <w:sz w:val="23"/>
      <w:color w:val="111827"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Signature">
    <w:name w:val="Signature"/>
    <w:basedOn w:val="Normal"/>
    <w:qFormat/>
    <w:pPr>
      <w:spacing w:before="80" w:after="80"/>
    </w:pPr>
    <w:rPr>
      <w:sz w:val="21"/>
    </w:rPr>
  </w:style>
</w:styles>
'@

$settings = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:zoom w:percent="100"/>
  <w:defaultTabStop w:val="720"/>
  <w:compat>
    <w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/>
  </w:compat>
</w:settings>
'@

$fontTable = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:font w:name="Aptos">
    <w:panose1 w:val="020F0502020204030204"/>
    <w:charset w:val="00"/>
    <w:family w:val="swiss"/>
  </w:font>
</w:fonts>
'@

$theme = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">
  <a:themeElements>
    <a:clrScheme name="Office">
      <a:dk1><a:srgbClr val="000000"/></a:dk1>
      <a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>
      <a:dk2><a:srgbClr val="1F2937"/></a:dk2>
      <a:lt2><a:srgbClr val="F8FAFC"/></a:lt2>
      <a:accent1><a:srgbClr val="0F766E"/></a:accent1>
      <a:accent2><a:srgbClr val="2563EB"/></a:accent2>
      <a:accent3><a:srgbClr val="16A34A"/></a:accent3>
      <a:accent4><a:srgbClr val="EA580C"/></a:accent4>
      <a:accent5><a:srgbClr val="7C3AED"/></a:accent5>
      <a:accent6><a:srgbClr val="0891B2"/></a:accent6>
      <a:hlink><a:srgbClr val="2563EB"/></a:hlink>
      <a:folHlink><a:srgbClr val="7C3AED"/></a:folHlink>
    </a:clrScheme>
    <a:fontScheme name="Office">
      <a:majorFont><a:latin typeface="Aptos Display"/></a:majorFont>
      <a:minorFont><a:latin typeface="Aptos"/></a:minorFont>
    </a:fontScheme>
    <a:fmtScheme name="Office">
      <a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>
      <a:lnStyleLst><a:ln w="6350" cap="flat" cmpd="sng" algn="ctr"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>
      <a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>
      <a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst>
    </a:fmtScheme>
  </a:themeElements>
</a:theme>
'@

function P {
    param(
        [string]$Text,
        [string]$Style = "Normal",
        [string]$Jc = "",
        [switch]$Bold
    )
    $escaped = [System.Security.SecurityElement]::Escape($Text)
    $styleXml = if ($Style -ne "Normal") { "<w:pStyle w:val=""$Style""/>" } else { "" }
    $jcXml = if ($Jc) { "<w:jc w:val=""$Jc""/>" } else { "" }
    $boldXml = if ($Bold) { "<w:b/>" } else { "" }
    return "<w:p><w:pPr>$styleXml$jcXml</w:pPr><w:r><w:rPr>$boldXml</w:rPr><w:t xml:space=""preserve"">$escaped</w:t></w:r></w:p>"
}

function Bullet {
    param([string]$Text)
    $escaped = [System.Security.SecurityElement]::Escape($Text)
    return "<w:p><w:pPr><w:ind w:left=""720"" w:hanging=""360""/><w:spacing w:after=""90""/></w:pPr><w:r><w:t>- $escaped</w:t></w:r></w:p>"
}

$body = @()
$body += P "e258tech.tech" "Title"
$body += P (U "Proposta de Implementa\u00E7\u00E3o de Sistema de Gest\u00E3o Escolar") "Meta" "center"
$body += P (U "\u00C0 Direc\u00E7\u00E3o do Instituto Polit\u00E9cnico de Ci\u00EAncias da Terra e Ambiente") "Meta"
$body += P (U "Assunto: Proposta de Implementa\u00E7\u00E3o de Sistema de Gest\u00E3o Escolar") "Subject"
$body += P "Exmos. Senhores,"
$body += P (U "A e258tech.tech vem, por este meio, apresentar o seu interesse em colaborar com o Instituto Polit\u00E9cnico de Ci\u00EAncias da Terra e Ambiente na implementa\u00E7\u00E3o de um Sistema de Gest\u00E3o Escolar moderno, seguro e eficiente.")
$body += P (U "A nossa proposta tem como objectivo apoiar a institui\u00E7\u00E3o na digitaliza\u00E7\u00E3o e optimiza\u00E7\u00E3o dos seus processos administrativos, acad\u00E9micos e financeiros, permitindo uma gest\u00E3o mais organizada, r\u00E1pida e transparente.")
$body += P (U "O sistema poder\u00E1 incluir, entre outros, os seguintes m\u00F3dulos:")
$body += Bullet (U "Gest\u00E3o de estudantes;")
$body += Bullet (U "Gest\u00E3o de inscri\u00E7\u00F5es e matr\u00EDculas;")
$body += Bullet (U "Gest\u00E3o de turmas, cursos e disciplinas;")
$body += Bullet (U "Gest\u00E3o de docentes;")
$body += Bullet (U "Lan\u00E7amento e consulta de notas;")
$body += Bullet "Controlo de propinas e pagamentos;"
$body += Bullet (U "Emiss\u00E3o de recibos, declara\u00E7\u00F5es e relat\u00F3rios;")
$body += Bullet "Portal para estudantes e encarregados;"
$body += Bullet (U "Painel administrativo para a direc\u00E7\u00E3o e secretaria.")
$body += P (U "Acreditamos que esta solu\u00E7\u00E3o poder\u00E1 contribuir significativamente para melhorar a efici\u00EAncia operacional da institui\u00E7\u00E3o, reduzir processos manuais e facilitar o acesso \u00E0 informa\u00E7\u00E3o em tempo real.")
$body += P (U "A e258tech.tech coloca-se \u00E0 disposi\u00E7\u00E3o para realizar uma apresenta\u00E7\u00E3o t\u00E9cnica da solu\u00E7\u00E3o, compreender as necessidades espec\u00EDficas do Instituto e apresentar uma proposta detalhada de implementa\u00E7\u00E3o.")
$body += P (U "Sem outro assunto de momento, subscrevemo-nos com elevada considera\u00E7\u00E3o.")
$body += P "Atenciosamente," "Signature"
$body += P (U "Ol\u00EDmpia Constantino Chitlhango") "Signature" "" -Bold
$body += P "Directora Geral" "Signature"
$body += P "e258tech.tech" "Signature"
$body += P "Contacto: ____________________" "Signature"
$body += P "Email: ____________________" "Signature"
$body += P "Website: www.e258tech.tech" "Signature"
$body += P "Data: ____ / ____ / _______" "Signature"

$document = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $($body -join "`n    ")
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1260" w:right="1440" w:bottom="1260" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

Write-Utf8NoBom (Join-Path $buildDir "[Content_Types].xml") $contentTypes
Write-Utf8NoBom (Join-Path $buildDir "_rels\.rels") $rels
Write-Utf8NoBom (Join-Path $buildDir "docProps\core.xml") $core
Write-Utf8NoBom (Join-Path $buildDir "docProps\app.xml") $app
Write-Utf8NoBom (Join-Path $buildDir "word\_rels\document.xml.rels") $documentRels
Write-Utf8NoBom (Join-Path $buildDir "word\document.xml") $document
Write-Utf8NoBom (Join-Path $buildDir "word\styles.xml") $styles
Write-Utf8NoBom (Join-Path $buildDir "word\settings.xml") $settings
Write-Utf8NoBom (Join-Path $buildDir "word\fontTable.xml") $fontTable
Write-Utf8NoBom (Join-Path $buildDir "word\theme\theme1.xml") $theme

if (Test-Path $docxPath) {
    Remove-Item -LiteralPath $docxPath -Force
}

$zipPath = Join-Path $env:TEMP ("carta_ipcta_" + [guid]::NewGuid().ToString("N") + ".zip")
Compress-Archive -Path (Join-Path $buildDir "*") -DestinationPath $zipPath -Force
Move-Item -LiteralPath $zipPath -Destination $docxPath -Force
Remove-Item -LiteralPath $buildDir -Recurse -Force

Write-Output $docxPath
