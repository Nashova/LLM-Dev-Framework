<#
.SYNOPSIS
    Validaciones rapidas anti-rompimiento antes de commit/deploy. Cero side-effects.
.DESCRIPTION
    Generalizado a partir del safety-check de un proyecto real (ver
    examples/case-study-admin-console.md). Tres chequeos:
      1. Line endings LF en *.sh tracked (CRLF rompe containers Linux).
      2. Sintaxis de archivos .py modificados (AST parse) -- extender con
         mas lenguajes segun el stack del proyecto (ver el bloque 2 abajo).
      3. Aviso (no bloqueante) si se tocaron archivos de riesgo sin tocar
         ninguna doc viva -- ver _config.ps1: $RISK_SIGNAL_PATTERNS / $DOC_FILES.

    Exit code 0 si todo OK, 1 si encuentra fallas bloqueantes.
.EXAMPLE
    .\safety-check.ps1
    .\safety-check.ps1 -Quiet
#>

param([switch]$Quiet)

$configPath = Join-Path $PSScriptRoot "_config.ps1"
$configTemplatePath = Join-Path $PSScriptRoot "_config.template.ps1"
if (Test-Path $configPath) {
    . $configPath
} elseif (Test-Path $configTemplatePath) {
    Write-Host "  !  _config.ps1 no existe -- usando _config.template.ps1 como fallback." -ForegroundColor Yellow
    Write-Host "     Copia _config.template.ps1 a _config.ps1 y ajusta las variables de tu proyecto." -ForegroundColor Yellow
    . $configTemplatePath
} else {
    Write-Host "  !  Ni _config.ps1 ni _config.template.ps1 existen. Chequeos de doc viva deshabilitados." -ForegroundColor Yellow
    $global:RISK_SIGNAL_PATTERNS = @()
    $global:DOC_FILES = @()
}

$ErrorActionPreference = "Continue"
$failures = @()

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { Write-Host "ERROR: no estoy en un repo git" -ForegroundColor Red; exit 1 }
$repoRoot = $repoRoot.Trim().Replace("/", "\")

# ---------- 1. Line endings en *.sh tracked ----------
$shFiles = & git -C $repoRoot ls-files -- '*.sh' 2>$null | Sort-Object -Unique
$shCount = 0
foreach ($f in $shFiles) {
    if (-not $f) { continue }
    $shCount++
    $full = Join-Path $repoRoot $f
    if (-not (Test-Path $full)) { continue }
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $hasCRLF = $false
    for ($i = 0; $i -lt $bytes.Length - 1; $i++) {
        if ($bytes[$i] -eq 13 -and $bytes[$i+1] -eq 10) { $hasCRLF = $true; break }
    }
    if ($hasCRLF) {
        $failures += "CRLF en $f (rompe containers Linux -- forzar LF, ver .gitattributes)"
    }
}

# ---------- 2. Sintaxis de archivos modificados ----------
# TODO: adaptar al stack real. El patron: para cada lenguaje del proyecto,
# encontrar los archivos modificados de ESE lenguaje y correr un parse
# rapido (no un build completo -- eso ya lo va a atrapar el CI/build normal,
# esto es solo para no perder tiempo en un commit->push->deploy que va a
# fallar por un error de sintaxis trivial).
$pyChanged = & git -C $repoRoot status --porcelain 2>$null |
    Where-Object { $_ -match '\.py$' } |
    ForEach-Object { ($_ -replace '^...', '').Trim() } |
    Sort-Object -Unique

$pythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $pythonExe) { $pythonExe = (Get-Command python3 -ErrorAction SilentlyContinue).Source }

if ($pythonExe) {
    foreach ($f in $pyChanged) {
        if (-not $f) { continue }
        $full = Join-Path $repoRoot $f
        if (-not (Test-Path $full)) { continue }
        $py = "import ast, sys; ast.parse(open(sys.argv[1], encoding='utf-8').read())"
        $out = & $pythonExe -c $py $full 2>&1
        if ($LASTEXITCODE -ne 0) {
            $first = ($out -split "`n" | Select-Object -Last 1).Trim()
            $failures += "SyntaxError en $f -> $first"
        }
    }
}

# Ejemplo de como agregar otro lenguaje (JS/TS via esbuild, si esta disponible):
# $jsChanged = & git -C $repoRoot status --porcelain 2>$null |
#     Where-Object { $_ -match '\.(jsx|js|tsx|ts)$' } |
#     ForEach-Object { ($_ -replace '^...', '').Trim() } | Sort-Object -Unique
# $esbuildBin = Join-Path $repoRoot "node_modules\.bin\esbuild.cmd"
# if ((Test-Path $esbuildBin) -and $jsChanged) {
#     foreach ($f in $jsChanged) {
#         $null = & $esbuildBin (Join-Path $repoRoot $f) --log-level=error 2>&1 | Out-Null
#         if ($LASTEXITCODE -ne 0) { $failures += "JS/TS error en $f" }
#     }
# }

# ---------- 3. Documentacion viva desincronizada (no bloqueante) ----------
# CAVEAT conocido: `git status --porcelain` colapsa un directorio ENTERO
# nuevo/nunca trackeado a una sola linea (ej. `?? src/`) en vez de listar
# los archivos de adentro -- si tu cambio crea un directorio riesgoso
# COMPLETAMENTE nuevo, este chequeo puede no detectarlo hasta que corras
# `git add -A` primero (eso hace `ship.ps1` antes del commit). No se usa
# `-uall` para evitar el costo real en repos grandes con directorios
# untracked voluminosos (ver la nota de seguridad del harness sobre esto).
$changedFiles = & git -C $repoRoot status --porcelain 2>$null |
    ForEach-Object { ($_ -replace '^...', '').Trim() } | Where-Object { $_ }

$touchedSignal = $changedFiles | Where-Object { $f = $_; $RISK_SIGNAL_PATTERNS | Where-Object { $f -match $_ } }
$touchedDocs = $changedFiles | Where-Object { $DOC_FILES -contains $_ }

if ($touchedSignal -and -not $touchedDocs) {
    Write-Host ""
    Write-Host "  !  Aviso: tocaste archivos de riesgo sin tocar ninguna doc viva" -ForegroundColor Yellow
    Write-Host "     ($($DOC_FILES -join ', '))." -ForegroundColor Yellow
    Write-Host "     Si el cambio agrega/cambia una regla de negocio o decision operativa, actualiza la doc" -ForegroundColor Yellow
    Write-Host "     correspondiente en el mismo commit. Si es un fix menor sin impacto de diseno, ignora este aviso." -ForegroundColor Yellow
}

# ---------- 4. Resumen ----------
if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "  X  Safety check FAILED" -ForegroundColor Red
    foreach ($f in $failures) { Write-Host "     - $f" -ForegroundColor Red }
    Write-Host ""
    exit 1
}

if (-not $Quiet) {
    Write-Host "  OK  Safety check ($shCount .sh tracked, $($pyChanged.Count) .py modificados)" -ForegroundColor Green
}
exit 0
