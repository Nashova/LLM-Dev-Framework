<#
.SYNOPSIS
    Crea o detecta un Pull Request existente, sin importar el proveedor de
    git. Dot-sourceado por ship.ps1.
.DESCRIPTION
    Patron: autenticar con un token (Bearer o Basic segun el proveedor),
    GET para ver si ya hay un PR abierto desde esta rama, POST para crear
    uno si no. Usa Invoke-RestMethod (stack TLS nativo de Windows) en vez
    de un CLI de terceros (gh/az/glab) -- ver README.md de esta carpeta
    para por que esto importa en redes corporativas con inspeccion TLS.

    GitHub, Azure DevOps y GitLab: implementados completos.
    Bitbucket: esqueleto con el endpoint exacto en un comentario --
    completar siguiendo el mismo patron.
#>

function Get-GitProviderFromRemote {
    param([string]$RemoteUrl)
    if ($RemoteUrl -match 'github\.com') { return 'github' }
    if ($RemoteUrl -match 'dev\.azure\.com|visualstudio\.com') { return 'azuredevops' }
    if ($RemoteUrl -match 'gitlab') { return 'gitlab' }
    if ($RemoteUrl -match 'bitbucket') { return 'bitbucket' }
    return 'unknown'
}

function New-OrUpdatePullRequest {
    <#
    .PARAMETER Branch
        Rama origen del PR (la que se acaba de pushear).
    .PARAMETER BaseBranch
        Rama destino (tipicamente 'main' o 'master').
    .PARAMETER Title
        Titulo del PR (primera linea del mensaje de commit, tipicamente).
    .PARAMETER Description
        Cuerpo del PR (mensaje de commit completo, tipicamente).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$Branch,
        [string]$BaseBranch = "main",
        [Parameter(Mandatory=$true)][string]$Title,
        [string]$Description = ""
    )

    $originUrl = (& git remote get-url origin)
    $provider = Get-GitProviderFromRemote -RemoteUrl $originUrl

    switch ($provider) {
        'github' {
            $ghAvailable = $null -ne (Get-Command gh -ErrorAction SilentlyContinue)
            if ($ghAvailable) {
                $existing = $null
                try { $existing = & gh pr view --json url,state 2>$null | ConvertFrom-Json } catch {}
                if ($existing -and $existing.state -eq 'OPEN') {
                    Write-Host "  PR existente actualizado: $($existing.url)" -ForegroundColor Green
                    return
                }
                & gh pr create --base $BaseBranch --title $Title --body $Description
                return
            }
            # Fallback sin gh: API REST de GitHub con un Personal Access Token.
            $token = Get-ProjectSecret -Name "github_token"
            $repoPath = ($originUrl -replace '.*github\.com[:/]', '' -replace '\.git$', '')
            $headers = @{ Authorization = "Bearer $token"; Accept = "application/vnd.github+json" }
            $listUrl = "https://api.github.com/repos/$repoPath/pulls?head=$(($repoPath -split '/')[0]):$Branch&state=open"
            $existing = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get
            if ($existing.Count -gt 0) {
                Write-Host "  PR existente actualizado: $($existing[0].html_url)" -ForegroundColor Green
                return
            }
            $body = @{ title = $Title; head = $Branch; base = $BaseBranch; body = $Description } | ConvertTo-Json
            $created = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoPath/pulls" -Headers $headers -Method Post -Body $body
            Write-Host "  PR creado: $($created.html_url)" -ForegroundColor Green
        }

        'azuredevops' {
            # Requiere $ADO_ORG/$ADO_PROJECT/$ADO_REPO en _config.ps1 y
            # Get-ProjectSecret -Name "azuredevops_pat" (scope minimo: Code
            # Read & write). Ver examples/case-study-admin-console.md para el
            # hallazgo real de por que esto es API REST directa y no `az`.
            $pat = Get-ProjectSecret -Name "azuredevops_pat"
            $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
            $headers = @{ Authorization = "Basic $b64" }

            $listUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/git/repositories/$ADO_REPO/pullrequests?searchCriteria.sourceRefName=refs/heads/$Branch&searchCriteria.status=active&api-version=7.1"
            $existing = $null
            try {
                $resp = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get -ErrorAction Stop
                if ($resp.count -gt 0) { $existing = $resp.value[0] }
            } catch {}

            if ($existing) {
                $prUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_REPO/pullrequest/$($existing.pullRequestId)"
                Write-Host "  PR existente actualizado automaticamente por el push: $prUrl" -ForegroundColor Green
                return
            }

            $createUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/git/repositories/$ADO_REPO/pullrequests?api-version=7.1"
            $body = @{ sourceRefName = "refs/heads/$Branch"; targetRefName = "refs/heads/$BaseBranch"; title = $Title; description = $Description } | ConvertTo-Json
            $created = Invoke-RestMethod -Uri $createUrl -Headers ($headers + @{ "Content-Type" = "application/json" }) -Method Post -Body $body
            $prUrl = "https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_REPO/pullrequest/$($created.pullRequestId)"
            Write-Host "  PR creado: $prUrl" -ForegroundColor Green
        }

        'gitlab' {
            # Token: Get-ProjectSecret -Name "gitlab_token" (scope: api).
            # El project ID se infiere del path URL-encoded del remoto origin.
            $token = Get-ProjectSecret -Name "gitlab_token"
            $headers = @{ "PRIVATE-TOKEN" = $token }

            # Extraer host y path del remoto (soporta SSH y HTTPS)
            $gitlabHost = "gitlab.com"
            $projectPath = ""
            if ($originUrl -match '(?:https?://([^/]+)/|git@([^:]+):)(.+?)(?:\.git)?$') {
                $gitlabHost = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
                $projectPath = $Matches[3]
            }
            $encodedProject = [uri]::EscapeDataString($projectPath)

            # Listar MRs abiertos desde esta rama
            $listUrl = "https://$gitlabHost/api/v4/projects/$encodedProject/merge_requests?source_branch=$Branch&state=opened"
            $existing = $null
            try {
                $existing = Invoke-RestMethod -Uri $listUrl -Headers $headers -Method Get -ErrorAction Stop
            } catch {}

            if ($existing -and $existing.Count -gt 0) {
                Write-Host "  MR existente actualizado: $($existing[0].web_url)" -ForegroundColor Green
                return
            }

            # Crear MR nuevo
            $createUrl = "https://$gitlabHost/api/v4/projects/$encodedProject/merge_requests"
            $body = @{
                source_branch = $Branch
                target_branch = $BaseBranch
                title         = $Title
                description   = $Description
            } | ConvertTo-Json
            $created = Invoke-RestMethod -Uri $createUrl -Headers ($headers + @{ "Content-Type" = "application/json" }) -Method Post -Body $body
            Write-Host "  MR creado: $($created.web_url)" -ForegroundColor Green
        }

        'bitbucket' {
            # TODO: completar siguiendo el mismo patron.
            # Token: Get-ProjectSecret -Name "bitbucket_app_password".
            # Auth: Basic (usuario real + app password, Bitbucket no soporta
            # token-vacio como Azure DevOps).
            # Listar/crear PRs:
            #   GET/POST https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/pullrequests
            Write-Host "  Bitbucket no implementado todavia en este framework -- ver el TODO en git-provider-pr.ps1" -ForegroundColor Yellow
        }

        default {
            Write-Host "  Proveedor de git no reconocido ($originUrl). Crea el PR manualmente." -ForegroundColor Yellow
        }
    }
}
