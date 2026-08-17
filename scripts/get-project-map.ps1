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

# 2. Metricas y conteos de codigo
#
# Fuente primaria: `git ls-files`. Es instantaneo y ya respeta .gitignore, asi que nunca
# recorre node_modules / bin / obj / venv. La version anterior hacia SIETE recorridos
# recursivos completos del disco (uno por lenguaje) y filtraba despues con Where-Object,
# lo que en un proyecto con node_modules tardaba minutos y contaba dependencias ajenas
# como codigo propio. Solo se cae a un recorrido de disco si no es un repo git.
Write-Host "--- Conteos y Metricas de Codigo ---" -ForegroundColor Yellow
$metrics = @()

$allFiles = @()
Push-Location $targetPath
try {
    $tracked = git ls-files 2>$null
    if ($LASTEXITCODE -eq 0 -and $tracked) {
        $allFiles = @($tracked)
    } else {
        $skipDirs = @('node_modules', 'dist', 'build', 'bin', 'obj', 'venv', 'ENV', '__pycache__', 'vendor', 'target')
        $allFiles = @(
            Get-ChildItem -Path $targetPath -Recurse -File -ErrorAction SilentlyContinue |
                ForEach-Object { $_.FullName.Substring($targetPath.Length).TrimStart('\', '/') -replace '\\', '/' } |
                Where-Object {
                    $rel = $_
                    -not ($skipDirs | Where-Object { $rel -like "*/$_/*" -or $rel -like "$_/*" })
                }
        )
    }
} finally { Pop-Location }

function Get-ExtCount([string[]]$files, [string]$ext) {
    ($files | Where-Object { $_.ToLower().EndsWith($ext) } | Measure-Object).Count
}

# Ruby / Rails
$rbModels      = ($allFiles | Where-Object { $_ -match 'app/models/.*\.rb$' }      | Measure-Object).Count
$rbControllers = ($allFiles | Where-Object { $_ -match 'app/controllers/.*\.rb$' } | Measure-Object).Count
$rbServices    = ($allFiles | Where-Object { $_ -match 'app/services/.*\.rb$' }    | Measure-Object).Count
$rbSpecs       = ($allFiles | Where-Object { $_ -match '_spec\.rb$' }              | Measure-Object).Count
if ($rbModels -gt 0 -or $rbControllers -gt 0) {
    $metrics += "Ruby/Rails : $rbModels modelos, $rbControllers controladores, $rbServices servicios, $rbSpecs specs"
}

# TypeScript / JavaScript / Angular / React / Vue / Svelte
$tsFiles   = Get-ExtCount $allFiles '.ts'
$tsxFiles  = Get-ExtCount $allFiles '.tsx'
$jsFiles   = Get-ExtCount $allFiles '.js'
$jsxFiles  = Get-ExtCount $allFiles '.jsx'
$vueFiles  = Get-ExtCount $allFiles '.vue'
$svelteF   = Get-ExtCount $allFiles '.svelte'
$htmlFiles = Get-ExtCount $allFiles '.html'
if (($tsFiles + $tsxFiles + $jsFiles + $jsxFiles + $vueFiles + $svelteF) -gt 0) {
    $parts = @()
    if ($tsFiles -gt 0)   { $parts += "$tsFiles .ts" }
    if ($tsxFiles -gt 0)  { $parts += "$tsxFiles .tsx" }
    if ($jsFiles -gt 0)   { $parts += "$jsFiles .js" }
    if ($jsxFiles -gt 0)  { $parts += "$jsxFiles .jsx" }
    if ($vueFiles -gt 0)  { $parts += "$vueFiles .vue" }
    if ($svelteF -gt 0)   { $parts += "$svelteF .svelte" }
    if ($htmlFiles -gt 0) { $parts += "$htmlFiles .html" }
    $metrics += "Frontend   : " + ($parts -join ", ")
}

# Python
$pyFiles = Get-ExtCount $allFiles '.py'
$pyTests = ($allFiles | Where-Object { $_ -match '(^|/)(test_[^/]*|[^/]*_test)\.py$' } | Measure-Object).Count
if ($pyFiles -gt 0) { $metrics += "Python     : $pyFiles archivos .py (incluye $pyTests tests)" }

# .NET / C#
$csFiles = Get-ExtCount $allFiles '.cs'
$csTests = ($allFiles | Where-Object { $_ -match '(?i)tests?/.*\.cs$' } | Measure-Object).Count
if ($csFiles -gt 0) { $metrics += ".NET / C#  : $csFiles archivos .cs (incluye $csTests en carpetas de test)" }

# Go
$goFiles = Get-ExtCount $allFiles '.go'
$goTests = ($allFiles | Where-Object { $_ -match '_test\.go$' } | Measure-Object).Count
if ($goFiles -gt 0) { $metrics += "Go         : $goFiles archivos .go (incluye $goTests tests)" }

# Java / Kotlin
$javaFiles = Get-ExtCount $allFiles '.java'
$ktFiles   = Get-ExtCount $allFiles '.kt'
if (($javaFiles + $ktFiles) -gt 0) { $metrics += "JVM        : $javaFiles archivos .java, $ktFiles .kt" }

# PHP
$phpFiles = Get-ExtCount $allFiles '.php'
if ($phpFiles -gt 0) { $metrics += "PHP        : $phpFiles archivos .php" }

# Rust
$rsFiles = Get-ExtCount $allFiles '.rs'
if ($rsFiles -gt 0) { $metrics += "Rust       : $rsFiles archivos .rs" }

# Swift
$swiftFiles = Get-ExtCount $allFiles '.swift'
if ($swiftFiles -gt 0) { $metrics += "Swift      : $swiftFiles archivos .swift" }

# SQL
$sqlFiles = Get-ExtCount $allFiles '.sql'
if ($sqlFiles -gt 0) { $metrics += "SQL        : $sqlFiles archivos .sql" }

# Scripts de operacion
$shFiles  = Get-ExtCount $allFiles '.sh'
$ps1Files = Get-ExtCount $allFiles '.ps1'
if (($shFiles + $ps1Files) -gt 0) { $metrics += "Scripts    : $shFiles .sh, $ps1Files .ps1" }

# Docs
$mdDocs = Get-ExtCount $allFiles '.md'
$metrics += "Docs (.md) : $mdDocs documentos Markdown"
$metrics += "TOTAL      : $(($allFiles | Measure-Object).Count) archivos considerados"

foreach ($m in $metrics) { Write-Host ("  " + $m) }

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
