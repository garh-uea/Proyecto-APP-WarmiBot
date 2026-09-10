$ErrorActionPreference = 'Stop'
$inputDocx = 'C:\WarmiBot\output\Semana_11_Taller_PLSQL_Parte2_Empleados.docx'
$outputPdf = 'C:\WarmiBot\rendered\parte2_empleados\Semana_11_Taller_PLSQL_Parte2_Empleados.pdf'
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
