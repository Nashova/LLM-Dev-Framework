# get-project-map.ps1 - Generador universal de mapa de estado para LLMs y desarrolladores
# Inspecciona el repositorio actual (monorepo, multi-repo o repo estándar) y muestra un
# resumen instantáneo de: ramas activas, archivos modificados/sin commitear, últimos commits,
# métricas de código y configuración de puertos.
#
# Uso: powershell -File scripts/get-project-map.ps1 [-RootPath .]

param(
    [string]$RootPath = "."
)

$targetPath = (Resolve-Path $RootPath).Path
$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"

Write-Host "================ MAPA DEL PROYECTO ================" -ForegroundColor Cyan
Write-Host "Raiz: $targetPath   Fecha: $dateStr`n"

# 1. Detectar repositorios Git anidados o repo raíz
$gitRepos = @()
if (Test-Path (Join-Path $targetPath ".git")) {
    $gitRepos += @{ Name = "RAIZ"; Path = $targetPath; IsRoot = $true }
}

Get-ChildItem -Path $targetPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $subGit = Join-Path $_.FullName ".git"
    if (Test-Path $subGit) {
        $gitRepos += @{ Name = $_.Name; Path = $_.FullName; IsRoot = $false }
    }
}

foreach ($repo in $gitRepos) {
    Write-Host ("--- " + $repo.Name + " ---") -ForegroundColor Yellow
    Push-Location $repo.Path
    try {
        $branch = (git branch --show-current 2>$null)
        if (-not $branch) { $branch = "(detached / sin rama)" }
        Write-Host "rama actual : $branch"
        
        $statusLines = (git status --short 2>$null)
        $dirtyCount = ($statusLines | Measure-Object).Count
        if ($dirtyCount -gt 0) {
            Write-Host "pendientes  : $dirtyCount archivo(s) sin commitear" -ForegroundColor Red
            $statusLines | Select-Object -First 6 | ForEach-Object { Write-Host ("   " + $_) }
            if ($dirtyCount -gt 6) { Write-Host "   ... ($($dirtyCount - 6) mas)" -ForegroundColor Gray }
        } else {
            Write-Host "pendientes  : limpio" -ForegroundColor Green
        }
        
        Write-Host "ultimos commits:" -ForegroundColor Gray
        git log -n 3 --oneline 2>$null | ForEach-Object { Write-Host ("   " + $_) }
    } finally {
        Pop-Location
    }
    Write-Host ""
}

# 2. Métricas y conteos de código
Write-Host "--- Conteos y Metricas de Codigo ---" -ForegroundColor Yellow
$metrics = @()

# Ruby / Rails
$rbModels = (Get-ChildItem -Path $targetPath -Filter "*.rb" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "app[\\/]models" } | Measure-Object).Count
$rbControllers = (Get-ChildItem -Path $targetPath -Filter "*.rb" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "app[\\/]controllers" } | Measure-Object).Count
$rbServices = (Get-ChildItem -Path $targetPath -Filter "*.rb" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -match "app[\\/]services" } | Measure-Object).Count
$rbSpecs = (Get-ChildItem -Path $targetPath -Filter "*_spec.rb" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
if ($rbModels -gt 0 -or $rbControllers -gt 0) {
    $metrics += "Ruby/Rails : $rbModels modelos, $rbControllers controladores, $rbServices servicios, $rbSpecs specs"
}

# TypeScript / Angular / React / Vue
$tsFiles = (Get-ChildItem -Path $targetPath -Filter "*.ts" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules|dist|build" } | Measure-Object).Count
$htmlTemplates = (Get-ChildItem -Path $targetPath -Filter "*.html" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules|dist|build" } | Measure-Object).Count
$jsxFiles = (Get-ChildItem -Path $targetPath -Filter "*.tsx" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules|dist|build" } | Measure-Object).Count
if ($tsFiles -gt 0 -or $jsxFiles -gt 0) {
    $metrics += "Frontend   : $tsFiles archivos .ts, $jsxFiles archivos .tsx, $htmlTemplates plantillas .html"
}

# Python / FastAPI / Django / Flask
$pyFiles = (Get-ChildItem -Path $targetPath -Filter "*.py" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "venv|ENV|__pycache__" } | Measure-Object).Count
$pyTests = (Get-ChildItem -Path $targetPath -Filter "test_*.py" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "venv|ENV" } | Measure-Object).Count
if ($pyFiles -gt 0) {
    $metrics += "Python     : $pyFiles archivos .py (incluye $pyTests tests)"
}

# .NET / C#
$csFiles = (Get-ChildItem -Path $targetPath -Filter "*.cs" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "bin|obj" } | Measure-Object).Count
if ($csFiles -gt 0) {
    $metrics += ".NET / C#  : $csFiles archivos de codigo .cs"
}

# Docs
$mdDocs = (Get-ChildItem -Path $targetPath -Filter "*.md" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -notmatch "node_modules|dist" } | Measure-Object).Count
$metrics += "Docs (.md) : $mdDocs documentos Markdown"

foreach ($m in $metrics) {
    Write-Host ("  " + $m)
}

# 3. Puertos Docker Compose
$composeFiles = Get-ChildItem -Path $targetPath -Filter "docker-compose*.yml" -Recurse -ErrorAction SilentlyContinue
if ($composeFiles) {
    Write-Host "`n--- Puertos Mapeados (Docker Compose) ---" -ForegroundColor Yellow
    foreach ($cf in $composeFiles) {
        $relPath = $cf.FullName.Substring($targetPath.Length).TrimStart('\', '/')
        $ports = Get-Content $cf.FullName | Select-String -Pattern '"?([0-9]{2,5}:[0-9]{2,5})"?'
        if ($ports) {
            $portList = ($ports | ForEach-Object { $_.Matches[0].Groups[1].Value }) -join ", "
            Write-Host ("  $relPath : $portList") -ForegroundColor Gray
        }
    }
}

Write-Host "`n====================================================`n"
