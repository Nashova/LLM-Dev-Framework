# bootstrap-ai.ps1 - Inicializador universal de conectividad Multi-IA
# Crea o sincroniza los puntos de entrada para cualquier asistente de IA (Claude, Gemini,
# Antigravity, Cursor, Copilot, Windsurf) basandose en AGENT_GUIDE.md como fuente unica de verdad.
#
# SEGURIDAD: nunca sobrescribe un archivo que no haya generado el mismo. Si encuentra un
# CLAUDE.md/.cursorrules/etc. escrito a mano, lo deja intacto y avisa. Con -Force lo respalda
# como <archivo>.bak antes de reemplazarlo.
#
# Uso: powershell -File scripts/bootstrap-ai.ps1 [-TargetDir .] [-Force] [-DryRun]

param(
    [string]$TargetDir = ".",
    [switch]$Force,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root = (Resolve-Path $TargetDir).Path
$sourceGuide = Join-Path $root "AGENT_GUIDE.md"

if (-not (Test-Path $sourceGuide)) {
    Write-Host "Error: No se encontro AGENT_GUIDE.md en $root" -ForegroundColor Red
    Write-Host "  bootstrap-ai se corre desde la raiz de TU proyecto, con tu AGENT_GUIDE.md ya copiado ahi." -ForegroundColor Yellow
    exit 1
}

$marker = "<!-- ARCHIVO AUTOGENERADO DESDE AGENT_GUIDE.md - NO EDITAR DIRECTAMENTE -->"

Write-Host "--- Sincronizando Configuracion Multi-IA ---" -ForegroundColor Cyan
Write-Host "Fuente de verdad: $sourceGuide"
if ($DryRun) { Write-Host "MODO DRY-RUN: no se escribe ningun archivo." -ForegroundColor Yellow }
Write-Host ""

# AGENTS.md va en la raiz: es la convencion emergente multi-herramienta que documenta
# AGENT_GUIDE.md, no un subdirectorio propio.
$targets = @(
    @{ Name = "Claude Code";                Path = (Join-Path $root "CLAUDE.md") },
    @{ Name = "Antigravity / Gemini";       Path = (Join-Path $root "GEMINI.md") },
    @{ Name = "Convencion multi-agente";    Path = (Join-Path $root "AGENTS.md") },
    @{ Name = "Cursor Rules";               Path = (Join-Path $root ".cursorrules") },
    @{ Name = "Windsurf Rules";             Path = (Join-Path $root ".windsurfrules") },
    @{ Name = "GitHub Copilot";             Path = (Join-Path (Join-Path $root ".github") "copilot-instructions.md") }
)

$content = Get-Content $sourceGuide -Raw
$payload = $marker + "`n`n" + $content
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

$written = 0; $skipped = 0; $backed = 0

foreach ($t in $targets) {
    $leaf = Split-Path $t.Path -Leaf

    if (Test-Path $t.Path) {
        $existing = [System.IO.File]::ReadAllText($t.Path)
        $isOurs = $existing.StartsWith($marker)

        if (-not $isOurs) {
            if (-not $Force) {
                Write-Host ("  [OMITIDO] " + $t.Name + " -> " + $leaf + " ya existe y NO fue generado por este script.") -ForegroundColor Yellow
                Write-Host ("             No se toco. Usa -Force para respaldarlo como " + $leaf + ".bak y reemplazarlo.") -ForegroundColor DarkGray
                $skipped++
                continue
            }
            if (-not $DryRun) { Copy-Item -LiteralPath $t.Path -Destination ($t.Path + ".bak") -Force }
            Write-Host ("  [RESPALDO] " + $leaf + " -> " + $leaf + ".bak") -ForegroundColor Magenta
            $backed++
        }
    }

    $parent = Split-Path $t.Path -Parent
    if (-not (Test-Path $parent)) {
        if (-not $DryRun) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    }

    if (-not $DryRun) { [System.IO.File]::WriteAllText($t.Path, $payload, $utf8NoBom) }
    Write-Host ("  [OK] " + $t.Name + " -> " + $leaf) -ForegroundColor Green
    $written++
}

Write-Host ""
Write-Host ("Resumen: {0} generados, {1} omitidos, {2} respaldados." -f $written, $skipped, $backed) -ForegroundColor Green
if ($skipped -gt 0) {
    Write-Host "Hubo archivos preexistentes que se dejaron intactos. Revisa la lista de arriba." -ForegroundColor Yellow
}
