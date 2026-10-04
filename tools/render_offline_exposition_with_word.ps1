$ErrorActionPreference = 'Stop'
$inputDocx = 'C:\WarmiBot\docs\Guion_Exposicion_Modo_Sin_Conexion_WarmiBot.docx'
$outputPdf = 'C:\WarmiBot\output\offline_doc_render\Guion_Exposicion_Modo_Sin_Conexion_WarmiBot.pdf'
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $outputPdf) | Out-Null
$word = New-Object -ComObject Word.Application
$word.Visible = $false
$word.DisplayAlerts = 0
try {
    $doc = $word.Documents.Open($inputDocx, $false, $true)
    $doc.ExportAsFixedFormat($outputPdf, 17)
    $doc.Close($false)
}
finally {
    $word.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
Write-Output $outputPdf
