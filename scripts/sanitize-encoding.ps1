# sanitize-encoding.ps1 - Limpieza universal de caracteres no validos y normalizacion UTF-8
# Remueve caracteres de control prohibidos en XML (\x00-\x08, \x0B-\x0C, \x0E-\x1F) de archivos
# de texto ya codificados en UTF-8, y los reescribe como UTF-8 sin BOM.
#
# SEGURIDAD:
#   - Solo toca archivos que YA son UTF-8 valido. Un archivo en Latin-1/Windows-1252 se OMITE
#     con aviso, nunca se reescribe: decodificarlo como UTF-8 lo llenaria de U+FFFD y destruiria
#     los bytes originales de forma irreversible.
#   - -DryRun reporta que cambiaria sin escribir nada. Correlo primero.
#   - Con -Backup deja un <archivo>.bak antes de reescribir.
#
# Uso: powershell -File scripts/sanitize-encoding.ps1 [-Path .] [-DryRun] [-Backup]

param(
    [string]$Path = ".",
    [switch]$DryRun,
    [switch]$Backup
)

$ErrorActionPreference = "Stop"

$target = (Resolve-Path $Path).Path
Write-Host "--- Limpieza y Normalizacion UTF-8 ---" -ForegroundColor Cyan
Write-Host "Ruta: $target"
if ($DryRun) { Write-Host "MODO DRY-RUN: no se escribe ningun archivo." -ForegroundColor Yellow }
Write-Host ""

$files = Get-ChildItem -Path $target -Include *.md,*.ps1,*.sh,*.txt,*.json,*.yml,*.yaml -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -notmatch "node_modules|\.git|dist|build|venv|\.bak$" }

# throwOnInvalidBytes = true: asi detectamos un archivo que NO es UTF-8 en vez de corromperlo.
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
$utf8NoBom  = New-Object System.Text.UTF8Encoding $false

$sanitized = 0; $skipped = 0

foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)

    try {
        $text = $strictUtf8.GetString($bytes)
    } catch [System.Text.DecoderFallbackException] {
        Write-Host ("  [OMITIDO] " + $f.Name + " no es UTF-8 valido. Conviertelo a UTF-8 primero.") -ForegroundColor Yellow
        $skipped++
        continue
    }

    $cleanChars = New-Object System.Text.StringBuilder $text.Length
    $modified = $false

    for ($i = 0; $i -lt $text.Length; $i++) {
        $c  = $text[$i]
        $cp = [int][char]$c
        if ($cp -eq 0x9 -or $cp -eq 0xA -or $cp -eq 0xD -or ($cp -ge 0x20 -and $cp -le 0xD7FF) -or ($cp -ge 0xE000 -and $cp -le 0xFFFD)) {
            [void]$cleanChars.Append($c)
        } else {
            $modified = $true
        }
    }

    if ($modified) {
        if ($DryRun) {
            Write-Host ("  [CAMBIARIA] " + $f.Name) -ForegroundColor Yellow
        } else {
            if ($Backup) { Copy-Item -LiteralPath $f.FullName -Destination ($f.FullName + ".bak") -Force }
            [System.IO.File]::WriteAllText($f.FullName, $cleanChars.ToString(), $utf8NoBom)
            Write-Host ("  [SANITIZADO] " + $f.Name) -ForegroundColor Yellow
        }
        $sanitized++
    }
}

Write-Host ""
if ($DryRun) {
    Write-Host ("Revision finalizada. Archivos que cambiarian: {0}. Omitidos por encoding: {1}." -f $sanitized, $skipped) -ForegroundColor Green
} else {
    Write-Host ("Revision finalizada. Archivos sanitizados: {0}. Omitidos por encoding: {1}." -f $sanitized, $skipped) -ForegroundColor Green
}
