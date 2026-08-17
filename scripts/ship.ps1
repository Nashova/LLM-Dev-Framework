<#
.SYNOPSIS
    Flujo completo: safety-check -> commit -> [deploy] -> push -> PR.
.DESCRIPTION
    Generalizado a partir del ship.ps1 de un proyecto real. Colapsa el flujo "termine
    de programar esto" en un solo comando -- ver
    docs/00_philosophy/why-scripts-not-instructions.md del framework para
    por que esto vale la pena como UN comando y no 4 pasos sueltos.

    Si la rama ya tiene un PR/MR abierto, NO crea uno nuevo -- el push
    actualiza el existente automaticamente (comportamiento nativo de todo
    proveedor de git moderno).
.PARAMETER Message
    Mensaje del commit.
.PARAMETER Deploy
    Corre $DEPLOY_SCRIPT (definido en _config.ps1) despues del commit,
    antes del push. No-op si $DEPLOY_SCRIPT es $null.
.PARAMETER NoPR
    No crea/actualiza el PR despues del push.
.PARAMETER BaseBranch
    Rama destino del PR. Default "main".
.EXAMPLE
    .\ship.ps1 -Message "fix: correct threshold" -Deploy
#>

param(
    [Parameter(Mandatory=$true, Position=0)][string]$Message,
    [switch]$Deploy,
    [switch]$NoPR,
    [string]$BaseBranch = "main"
)

$ErrorActionPreference = "Stop"

$repoRoot = (& git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { Write-Host "ERROR: no estoy en un repo git" -ForegroundColor Red; exit 1 }
$repoRoot = $repoRoot.Trim().Replace("/", "\")

. (Join-Path $PSScriptRoot "_config.ps1")
. (Join-Path $PSScriptRoot "git-provider-pr.ps1")

Push-Location $repoRoot
try {
    # ---------- 1. Safety check ----------
    Write-Host "`n[1/5] Safety check..." -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot "safety-check.ps1")
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Abortando: arregla los problemas y volve a correr." -ForegroundColor Red
        exit 1
    }

    # ---------- 2. Commit ----------
    $changes = & git status --porcelain
    if (-not $changes) {
        Write-Host "`nNada que commitear. Working tree limpio." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "`n[2/5] Commit..." -ForegroundColor Cyan
    & git add -A
    & git commit -m $Message
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Commit fallo. Abortando." -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # ---------- 3. Deploy (opcional) ----------
    if ($Deploy -and $DEPLOY_SCRIPT -and (Test-Path $DEPLOY_SCRIPT)) {
        Write-Host "`n[3/5] Deploy..." -ForegroundColor Cyan
        & $DEPLOY_SCRIPT
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Deploy fallo. El commit se mantiene; no pusheo." -ForegroundColor Red
            exit $LASTEXITCODE
        }
    } else {
        Write-Host "`n[3/5] (deploy salteado)" -ForegroundColor DarkGray
    }

    # ---------- 4. Push ----------
    $branch = (& git branch --show-current).Trim()
    Write-Host "`n[4/5] Push de $branch..." -ForegroundColor Cyan
    & git push -u origin $branch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Push fallo." -ForegroundColor Red
        exit $LASTEXITCODE
    }

    # ---------- 5. PR ----------
    if ($NoPR) {
        Write-Host "`n[5/5] PR salteado (-NoPR)" -ForegroundColor DarkGray
        return
    }
    Write-Host "`n[5/5] Creando/verificando PR..." -ForegroundColor Cyan
    $title = ($Message -split "`n")[0]
    New-OrUpdatePullRequest -Branch $branch -BaseBranch $BaseBranch -Title $title -Description $Message
} finally {
    Pop-Location
}
