# validate-knowledge-base.ps1 - Validador universal de citas en la documentacion
# Verifica que todas las rutas de archivo citadas entre backticks con separador de ruta
# existan en el codigo real del proyecto (evita documentacion que miente).
#
# Soporta:
#  - Citas con numero de linea (`app/models/user.rb:45`)
#  - Citas relativas al proyecto o submódulos
#  - Encabezados con '(rama `nombre_rama`)' para validar contra ramas remotas/locales
#
# Uso: powershell -File scripts/validate-knowledge-base.ps1 [-DocsPath docs] [-ProjectRoot .]

param(
    [string]$DocsPath = "docs",
    [string]$ProjectRoot = "."
)

$root = (Resolve-Path $ProjectRoot).Path
$docsDir = Join-Path $root $DocsPath
if (-not (Test-Path $docsDir)) {
    Write-Host "Error: No se encontro el directorio de documentacion en $docsDir" -ForegroundColor Red
    exit 1
}

Write-Host "--- Validando Citas de Codigo en Base de Conocimiento ---" -ForegroundColor Cyan
Write-Host "Raiz del Proyecto: $root"
Write-Host "Directorio Docs  : $docsDir`n"

$broken = 0
$checked = 0
$files = Get-ChildItem -Path $docsDir -Filter *.md -Recurse | Sort-Object Name
$regex = [regex]'`([A-Za-z0-9_\-./\\]+[\/\\][A-Za-z0-9_\-./\\]+\.(rb|ts|tsx|js|jsx|cs|py|go|rs|java|yml|yaml|json|sql|md|rake|ps1|sh|html|scss|css))(:[0-9\-]+)?`'
$headingBranchRegex = [regex]'^#+\s.*\(rama\s+`?([A-Za-z0-9_./-]+)`?\)'

function Test-InBranch($repoPath, $branch, $relPaths) {
    if (-not (Test-Path (Join-Path $repoPath ".git"))) { return $false }
    Push-Location $repoPath
    try {
        foreach ($rel in $relPaths) {
            $gitRel = $rel -replace '\\', '/'
            git cat-file -e "${branch}:${gitRel}" 2>$null
            if ($LASTEXITCODE -eq 0) { return $true }
        }
        return $false
    } finally { Pop-Location }
}

foreach ($doc in $files) {
    $branchContext = $null
    $lines = Get-Content $doc.FullName
    
    foreach ($line in $lines) {
        if ($line -match '^#+\s') {
            $hm = $headingBranchRegex.Match($line)
            $branchContext = if ($hm.Success) { $hm.Groups[1].Value } else { $null }
        }
        if ($line -match '\(nuevo|\(propuesto|\(template|\(ejemplo|\(generado') { continue }
        
        foreach ($m in $regex.Matches($line)) {
            $cite = $m.Groups[1].Value -replace '/', '\'
            $candidates = New-Object System.Collections.ArrayList
            
            [void]$candidates.Add((Join-Path $root $cite))
            [void]$candidates.Add((Join-Path $doc.DirectoryName $cite))
            
            # Buscar en subcarpetas de primer nivel (submódulos)
            Get-ChildItem -Path $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                [void]$candidates.Add((Join-Path $_.FullName $cite))
                [void]$candidates.Add((Join-Path (Join-Path $_.FullName "src") $cite))
                [void]$candidates.Add((Join-Path (Join-Path $_.FullName "app") $cite))
            }
            
            $checked++
            $found = $false
            foreach ($cand in $candidates) {
                if (Test-Path $cand) { $found = $true; break }
            }
            
            if (-not $found -and $null -ne $branchContext) {
                $relCandidates = @($cite, "src\$cite", "app\$cite")
                if (Test-InBranch $root $branchContext $relCandidates) { $found = $true }
            }
            
            if (-not $found) {
                $relDoc = $doc.FullName.Substring($root.Length).TrimStart('\', '/')
                Write-Host ("  [ROTA] " + $relDoc + " cita: " + $m.Groups[1].Value) -ForegroundColor Red
                $broken++
            }
        }
    }
}

Write-Host ""
Write-Host ("Citas revisadas: $checked   Rotas: $broken")
if ($broken -eq 0) {
    Write-Host "Base de Conocimiento 100% consistente con el codigo." -ForegroundColor Green
    exit 0
} else {
    Write-Host "Error: Existen citas rotas. Actualizar los documentos marcados." -ForegroundColor Red
    exit 1
}
