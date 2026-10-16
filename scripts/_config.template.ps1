<#
.SYNOPSIS
    Configuracion compartida de los scripts operativos. Copiar a _config.ps1
    en el proyecto real y rellenar las variables de abajo.
.DESCRIPTION
    Se dot-sourcea desde safety-check.ps1 y ship.ps1. Una sola fuente de
    verdad para rutas, patrones de riesgo, y credenciales (leidas en runtime
    desde un archivo gitignored, NUNCA hardcodeadas aca -- ver el hallazgo
    real documentado en examples/case-study-admin-console.md sobre por que un
    secreto hardcodeado en un script TRACKEADO queda expuesto para siempre
    en el historial de git, incluso despues de "corregirlo").
#>

# ============================================================================
# Deploy (opcional -- dejar $null si el proyecto no tiene un paso de deploy
# scriptable, ship.ps1 lo salta automaticamente)
# ============================================================================
$global:DEPLOY_SCRIPT = $null   # ej: "$PSScriptRoot\deploy.ps1"

# ============================================================================
# Azure DevOps (solo si el remoto origin es dev.azure.com / visualstudio.com).
# git-provider-pr.ps1 los exige para armar la URL de la API REST. Dejar en
# $null si el proyecto no usa Azure DevOps.
# ============================================================================
$global:ADO_ORG     = $null   # ej: "mi-organizacion"
$global:ADO_PROJECT = $null   # ej: "MiProyecto"
$global:ADO_REPO    = $null   # ej: "mi-repo"

# ============================================================================
# Chequeo de "doc viva desincronizada" (safety-check.ps1)
# ============================================================================
# Patrones de archivo (regex, se comparan contra `git status --porcelain`)
# que si se tocan SIN tocar ninguna doc de $DOC_FILES, disparan un aviso
# (no bloqueo). Ajustar a la estructura real del proyecto -- tipicamente:
# modelos de datos, capa de permisos/auth, migraciones, servicios core.
$global:RISK_SIGNAL_PATTERNS = @(
    'src/models/', 'src/api/auth\.', 'migrations/', 'src/services/'
)

# Docs que SI cuentan como "ya lo documentaste" cuando se tocan junto con
# un archivo de riesgo. Agregar aca CUALQUIER doc que el equipo use
# activamente para esto -- un doc que se actualiza en la practica pero no
# esta en esta lista genera avisos en falso (ver
# docs/00_philosophy/doc-freshness-strategy.md del framework).
$global:DOC_FILES = @(
    'AGENT_GUIDE.md', 'CLAUDE.md',
    'Docs/03_governance_and_guidelines/architecture.md',
    'Docs/03_governance_and_guidelines/change-safety.md',
    'Docs/03_governance_and_guidelines/CHANGELOG.md'
)

# ============================================================================
# Repos externos para validate-knowledge-base.ps1/.sh
# ============================================================================
# Si la documentacion de este proyecto cita a proposito archivos que viven en
# OTRO repo -- tipicamente este framework ("ver docs/03_architecture_patterns/
# xxx.md del framework") -- declaralo aca. Esas citas no estan rotas, pero sin
# esta lista el validador las reporta como tales, y un validador que siempre
# falla se ignora. Declarandolas, se VERIFICAN de verdad contra el disco en vez
# de ignorarse a ciegas. Rutas relativas a la raiz de este proyecto.
# Dejar vacio (@()) si el proyecto no cita ningun repo externo.
$global:KB_EXTERNAL_ROOTS = @()

# ============================================================================
# Credenciales -- NUNCA hardcodear un valor real aca. Este archivo, una vez
# copiado a _config.ps1, SI se trackea en git (a diferencia de los secretos
# reales). Ver secrets-management.md del framework para el patron completo.
# ============================================================================
function Get-ProjectSecret {
    <#
    .SYNOPSIS
        Lee un secreto por nombre desde el archivo local gitignored.
        Tira si el archivo o la clave no existen -- nunca cae a un default
        silencioso.
    .PARAMETER Name
        Nombre de la clave dentro de la seccion "secrets" del json.
    #>
    param([Parameter(Mandatory=$true)][string]$Name)
    $secretsPath = Join-Path (& git rev-parse --show-toplevel 2>$null) ".local\secrets.json"
    if (-not (Test-Path $secretsPath)) {
        throw "No encontre $secretsPath -- crear con el formato documentado en docs/03_architecture_patterns/secrets-management.md del framework."
    }
    $secrets = Get-Content $secretsPath -Raw | ConvertFrom-Json
    $value = $secrets.secrets.$Name
    if (-not $value) {
        throw "La clave '$Name' no existe en $secretsPath"
    }
    return $value
}
