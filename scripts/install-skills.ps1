<#
.SYNOPSIS
    Instala las skills del framework en el formato nativo de cada herramienta de IA.
.DESCRIPTION
    Gemelo funcional de install-skills.sh.

    Una skill se escribe UNA vez como skills/<nombre>/SKILL.md (formato Agent Skills: frontmatter
    con name + description). Este script la traduce al formato que cada herramienta espera, para no
    mantener seis copias divergentes a mano.

    SEGURIDAD: nunca sobrescribe un archivo que no haya generado el mismo (mismo criterio que
    bootstrap-ai). Con -Force lo respalda como <archivo>.bak antes de reemplazarlo.
.PARAMETER Target
    Raiz del proyecto destino. Default: directorio actual.
.PARAMETER Tool
    claude | cursor | copilot | windsurf | gemini | codex | continue | generic | all
    "generic" produce un solo LLM_PLAYBOOK.md, que es la via para cualquier herramienta o modelo
    local sin soporte nativo de skills.
.PARAMETER Skills
    Lista de skills a instalar. Default: todas.
.EXAMPLE
    powershell -File scripts/install-skills.ps1 -Target C:\proyectos\mi-app -Tool claude
.EXAMPLE
    powershell -File scripts/install-skills.ps1 -Target . -Tool all -DryRun
#>

param(
    [string]$Target = ".",
    [ValidateSet('claude','cursor','copilot','windsurf','gemini','codex','continue','generic','all')]
    [string]$Tool = "claude",
    [string[]]$Skills = @(),
    [switch]$DryRun,
    [switch]$Force,
    [switch]$List
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillsDir = Join-Path (Split-Path -Parent $scriptDir) "skills"

if (-not (Test-Path $skillsDir)) {
    Write-Host "ERROR: no encontre el directorio skills/ junto a scripts/." -ForegroundColor Red
    Write-Host "  Corre este script desde el repo del framework." -ForegroundColor Yellow
    exit 1
}

$marker = "<!-- GENERADO POR install-skills DESDE skills/<nombre>/SKILL.md - NO EDITAR DIRECTAMENTE -->"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Get-SkillNames {
    Get-ChildItem $skillsDir -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
        Select-Object -ExpandProperty Name | Sort-Object
}

function Get-SkillField([string]$path, [string]$field) {
    $lines = [IO.File]::ReadAllLines($path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return "" }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { break }
        $idx = $lines[$i].IndexOf(':')
        if ($idx -gt 0) {
            $key = $lines[$i].Substring(0, $idx).Trim()
            if ($key -eq $field) { return $lines[$i].Substring($idx + 1).Trim() }
        }
    }
    return ""
}

function Get-SkillBody([string]$path) {
    $lines = [IO.File]::ReadAllLines($path)
    if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return ($lines -join "`n") }
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { return (($lines[($i + 1)..($lines.Count - 1)]) -join "`n") }
    }
    return ""
}

# Escalar YAML de doble comilla. Sin esto, una description que contenga `: ` o empiece con una
# comilla rompe el parseo del frontmatter.
function ConvertTo-YamlString([string]$s) {
    '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"'
}

if ($List) {
    Write-Host "Skills disponibles en $skillsDir :" -ForegroundColor Cyan
    foreach ($s in Get-SkillNames) {
        $d = Get-SkillField (Join-Path $skillsDir "$s\SKILL.md") "description"
        if ($d.Length -gt 90) { $d = $d.Substring(0, 90) }
        Write-Host ("  {0,-24} {1}" -f $s, $d)
    }
    exit 0
}

if (-not (Test-Path $Target)) {
    Write-Host "ERROR: el directorio destino '$Target' no existe." -ForegroundColor Red
    exit 1
}
$targetFull = (Resolve-Path $Target).Path

$selected = @()
if ($Skills.Count -gt 0) {
    foreach ($s in $Skills) {
        if (Test-Path (Join-Path $skillsDir "$s\SKILL.md")) { $selected += $s }
        else {
            Write-Host "ERROR: la skill '$s' no existe. Corre -List para ver las disponibles." -ForegroundColor Red
            exit 1
        }
    }
} else {
    $selected = @(Get-SkillNames)
}

$script:written = 0; $script:skipped = 0; $script:backed = 0

function Write-Guarded([string]$dest, [string]$content) {
    $leaf = Split-Path $dest -Leaf

    # Se busca el marcador en TODO el archivo: en el formato de Claude va al final (el frontmatter
    # tiene que ser la primera linea) y en los demas va tras el cierre del frontmatter.
    if (Test-Path $dest) {
        $existing = [IO.File]::ReadAllText($dest)
        if (-not $existing.Contains("GENERADO POR install-skills")) {
            if (-not $Force) {
                Write-Host "  [OMITIDO] $leaf ya existe y no lo genero este script. Usa -Force para reemplazarlo." -ForegroundColor Yellow
                $script:skipped++
                return
            }
            if (-not $DryRun) { Copy-Item -LiteralPath $dest -Destination ($dest + ".bak") -Force }
            Write-Host "  [RESPALDO] $leaf -> $leaf.bak" -ForegroundColor Magenta
            $script:backed++
        }
    }

    if (-not $DryRun) {
        $parent = Split-Path $dest -Parent
        if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [IO.File]::WriteAllText($dest, $content, $utf8NoBom)
    }
    Write-Host ("  [OK] " + $dest.Substring($targetFull.Length).TrimStart('\','/')) -ForegroundColor Green
    $script:written++
}

function Install-Tool([string]$t) {
    Write-Host ""
    Write-Host "--- $t ---" -ForegroundColor Yellow

    if ($t -in @('gemini','codex','generic')) {
        # Herramientas de un solo archivo: se concatena todo en un playbook con tabla de ruteo.
        $sb = New-Object System.Text.StringBuilder
        [void]$sb.AppendLine($marker)
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("# Playbook de skills -- " + (Split-Path $targetFull -Leaf))
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("Este archivo concentra las skills del framework para herramientas que no tienen soporte nativo de")
        [void]$sb.AppendLine("skills. **Como usarlo**: lee la tabla de ruteo, identifica si la tarea actual encaja en alguna fila y,")
        [void]$sb.AppendLine("si encaja, lee esa seccion completa antes de actuar. Si ninguna aplica, segui normalmente.")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("## Tabla de ruteo")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("| Si la tarea es... | Lee la seccion |")
        [void]$sb.AppendLine("|---|---|")
        foreach ($n in $selected) {
            $d = Get-SkillField (Join-Path $skillsDir "$n\SKILL.md") "description"
            if ($d.Length -gt 150) { $d = $d.Substring(0, 150) }
            [void]$sb.AppendLine("| $d | [$n](#$n) |")
        }
        foreach ($n in $selected) {
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("---")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("<a id=""$n""></a>")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("# $n")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine((Get-SkillBody (Join-Path $skillsDir "$n\SKILL.md")))
        }
        $content = $sb.ToString()

        switch ($t) {
            'gemini' {
                Write-Guarded (Join-Path $targetFull ".gemini\skills-playbook.md") $content
                Write-Host "  NOTA: agrega a tu GEMINI.md la linea:  @.gemini/skills-playbook.md" -ForegroundColor Cyan
            }
            'codex' {
                Write-Guarded (Join-Path $targetFull ".agent-skills-playbook.md") $content
                Write-Host "  NOTA: referencia el playbook desde tu AGENTS.md." -ForegroundColor Cyan
            }
            'generic' {
                Write-Guarded (Join-Path $targetFull "LLM_PLAYBOOK.md") $content
                Write-Host "  NOTA: pega este archivo como system prompt, o pasalo como contexto al modelo local." -ForegroundColor Cyan
            }
        }
        return
    }

    foreach ($n in $selected) {
        $src  = Join-Path $skillsDir "$n\SKILL.md"
        $desc = ConvertTo-YamlString (Get-SkillField $src "description")
        $body = Get-SkillBody $src

        switch ($t) {
            'claude' {
                # Claude Code consume el formato nativo: se copia tal cual y el marcador va al final
                # para no desplazar el frontmatter de la primera linea.
                Write-Guarded (Join-Path $targetFull ".claude\skills\$n\SKILL.md") ([IO.File]::ReadAllText($src) + "`n" + $marker + "`n")
            }
            'cursor' {
                Write-Guarded (Join-Path $targetFull ".cursor\rules\$n.mdc") "---`ndescription: $desc`nalwaysApply: false`n---`n$marker`n$body"
            }
            'copilot' {
                Write-Guarded (Join-Path $targetFull ".github\instructions\$n.instructions.md") "---`napplyTo: '**'`ndescription: $desc`n---`n$marker`n$body"
            }
            'windsurf' {
                Write-Guarded (Join-Path $targetFull ".windsurf\rules\$n.md") "---`ntrigger: model_decision`ndescription: $desc`n---`n$marker`n$body"
            }
            'continue' {
                Write-Guarded (Join-Path $targetFull ".continue\rules\$n.md") "---`nname: $n`ndescription: $desc`n---`n$marker`n$body"
            }
        }
    }
}

Write-Host "--- Instalando skills del framework ---" -ForegroundColor Cyan
Write-Host "Origen  : $skillsDir"
Write-Host "Destino : $targetFull"
Write-Host ("Skills  : {0} ({1})" -f $selected.Count, ($selected -join ", "))
if ($DryRun) { Write-Host "MODO DRY-RUN: no se escribe nada." -ForegroundColor Yellow }

if ($Tool -eq 'all') {
    foreach ($t in @('claude','cursor','copilot','windsurf','continue','gemini','codex','generic')) { Install-Tool $t }
} else {
    Install-Tool $Tool
}

Write-Host ""
Write-Host ("Resumen: {0} escritos, {1} omitidos, {2} respaldados." -f $script:written, $script:skipped, $script:backed) -ForegroundColor Green
if ($script:skipped -gt 0) {
    Write-Host "Hubo archivos preexistentes que se dejaron intactos. Revisa la lista de arriba." -ForegroundColor Yellow
}
