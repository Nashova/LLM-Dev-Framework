#!/usr/bin/env bash
# Crea o detecta un Pull Request existente, sin importar el proveedor de git.
# Source-eado por ship.sh. Mismo patron que git-provider-pr.ps1 -- ver ese
# archivo para la explicacion completa. GitHub, Azure DevOps y GitLab
# implementados; Bitbucket no implementado (falla explicitamente, no en silencio).
#
# Dependencias: curl y python3 (para parsear JSON sin depender de jq).
#
# DOS REGLAS DE SEGURIDAD QUE ESTE ARCHIVO SOSTIENE:
#   1. El token NUNCA viaja como argumento de curl. Un argumento es visible en `ps` para
#      cualquier usuario del host. Se pasa por stdin via `curl --config -`.
#   2. Ninguna respuesta de error de la API se interpreta como exito. Se valida el codigo
#      HTTP y la forma del JSON antes de afirmar que un PR existe o se creo.

get_git_provider() {
    local remote_url="$1"
    if [[ "$remote_url" == *github.com* ]]; then echo "github"; return; fi
    if [[ "$remote_url" == *dev.azure.com* || "$remote_url" == *visualstudio.com* ]]; then echo "azuredevops"; return; fi
    if [[ "$remote_url" == *gitlab* ]]; then echo "gitlab"; return; fi
    if [[ "$remote_url" == *bitbucket* ]]; then echo "bitbucket"; return; fi
    echo "unknown"
}

# Body de la ultima llamada a _api_call. Se lee inmediatamente despues de invocarla.
_API_BODY=""

# _api_call <auth_header> <metodo> <url> <body|""> [args extra de curl...]
# Pasa el header de autorizacion por stdin para que el token no aparezca en `ps`.
# Devuelve 0 solo con HTTP 2xx; en cualquier otro caso imprime el error y devuelve 1.
_api_call() {
    local auth="$1" method="$2" url="$3" body="$4"
    shift 4

    local args=( -sS --config - -X "$method" -w '\n%{http_code}' )
    if [ -n "$body" ]; then
        args+=( -H "Content-Type: application/json" -d "$body" )
    fi
    args+=( "$@" "$url" )

    local raw status
    if ! raw=$(printf 'header = "%s"\n' "$auth" | curl "${args[@]}"); then
        echo "  ERROR: curl fallo al contactar $url" >&2
        return 1
    fi

    status="${raw##*$'\n'}"
    _API_BODY="${raw%$'\n'*}"

    case "$status" in
        2*) return 0 ;;
        *)
            echo "  ERROR: la API respondio HTTP $status" >&2
            echo "  Respuesta: $_API_BODY" >&2
            return 1
            ;;
    esac
}

# Extrae un valor del JSON en _API_BODY validando la forma esperada.
# _json_eval <expresion python sobre `d`>  (d = objeto ya parseado)
_json_eval() {
    printf '%s' "$_API_BODY" | "${PY_BIN:-python3}" -c "
import json, sys
try:
    d = json.load(sys.stdin)
except Exception as e:
    sys.stderr.write('  ERROR: respuesta de la API no es JSON valido: %s\n' % e)
    sys.exit(1)
try:
    sys.stdout.write(str($1))
except Exception as e:
    sys.stderr.write('  ERROR: la respuesta de la API no tiene la forma esperada (%s)\n' % e)
    sys.exit(1)
"
}

# Interprete de Python resuelto por _require_deps. En Windows, `command -v python3` puede
# resolver al App Execution Alias de la Microsoft Store, que existe pero no ejecuta nada:
# no basta con que el binario este en el PATH, hay que comprobar que corra.
PY_BIN=""

_require_deps() {
    local missing=0 candidate
    command -v curl >/dev/null 2>&1 || { echo "  ERROR: falta curl en el PATH." >&2; missing=1; }

    PY_BIN=""
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'pass' >/dev/null 2>&1; then
            PY_BIN="$candidate"
            break
        fi
    done
    if [ -z "$PY_BIN" ]; then
        echo "  ERROR: falta un python3 funcional en el PATH (se usa para parsear JSON sin jq)." >&2
        echo "         En Windows, usa la version PowerShell: scripts/ship.ps1" >&2
        missing=1
    fi
    return $missing
}

# new_or_update_pull_request <branch> <base_branch> <title> <description>
new_or_update_pull_request() {
    local branch="$1" base_branch="$2" title="$3" description="$4"
    local origin_url provider
    origin_url="$(git remote get-url origin)"
    provider="$(get_git_provider "$origin_url")"

    case "$provider" in
        github)
            if command -v gh >/dev/null 2>&1; then
                local existing_url
                existing_url=$(gh pr view --json url,state -q 'select(.state=="OPEN") | .url' 2>/dev/null || true)
                if [ -n "$existing_url" ]; then
                    echo "  PR existente actualizado: $existing_url"
                    return 0
                fi
                gh pr create --base "$base_branch" --title "$title" --body "$description" || return 1
                return 0
            fi

            # Fallback sin gh: API REST de GitHub con un Personal Access Token.
            _require_deps || return 1
            local token repo_path owner count body url
            token="$(get_project_secret github_token)" || return 1
            repo_path="$(echo "$origin_url" | sed -E 's#.*github\.com[:/]##; s#\.git$##')"
            owner="${repo_path%%/*}"

            _api_call "Authorization: Bearer $token" GET \
                "https://api.github.com/repos/$repo_path/pulls?head=${owner}:${branch}&state=open" "" \
                -H "Accept: application/vnd.github+json" || return 1

            # Un error de la API es un dict, no una lista: validarlo explicitamente.
            count=$(_json_eval "len(d) if isinstance(d, list) else (_ for _ in ()).throw(TypeError('se esperaba una lista de PRs'))") || return 1
            if [ "$count" -gt 0 ]; then
                url=$(_json_eval "d[0]['html_url']") || return 1
                echo "  PR existente actualizado: $url"
                return 0
            fi

            body=$("${PY_BIN:-python3}" -c "import json,sys; print(json.dumps({'title':sys.argv[1],'head':sys.argv[2],'base':sys.argv[3],'body':sys.argv[4]}))" \
                   "$title" "$branch" "$base_branch" "$description") || return 1
            _api_call "Authorization: Bearer $token" POST \
                "https://api.github.com/repos/$repo_path/pulls" "$body" \
                -H "Accept: application/vnd.github+json" || return 1
            url=$(_json_eval "d['html_url']") || return 1
            echo "  PR creado: $url"
            ;;

        azuredevops)
            # Requiere ADO_ORG/ADO_PROJECT/ADO_REPO en _config.sh y
            # get_project_secret azuredevops_pat (scope minimo: Code Read & write).
            _require_deps || return 1
            : "${ADO_ORG:?falta ADO_ORG en scripts/_config.sh}"
            : "${ADO_PROJECT:?falta ADO_PROJECT en scripts/_config.sh}"
            : "${ADO_REPO:?falta ADO_REPO en scripts/_config.sh}"

            local pat b64 auth list_url existing_id create_url body id
            pat="$(get_project_secret azuredevops_pat)" || return 1
            b64=$(printf ":%s" "$pat" | base64 -w0 2>/dev/null || printf ":%s" "$pat" | base64)
            auth="Authorization: Basic $b64"

            list_url="https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/git/repositories/$ADO_REPO/pullrequests?searchCriteria.sourceRefName=refs/heads/$branch&searchCriteria.status=active&api-version=7.1"
            _api_call "$auth" GET "$list_url" "" || return 1
            existing_id=$(_json_eval "d['value'][0]['pullRequestId'] if d.get('count', 0) > 0 else ''") || return 1

            if [ -n "$existing_id" ]; then
                echo "  PR existente actualizado automaticamente por el push: https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_REPO/pullrequest/$existing_id"
                return 0
            fi

            create_url="https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_apis/git/repositories/$ADO_REPO/pullrequests?api-version=7.1"
            body=$("${PY_BIN:-python3}" -c "import json,sys; print(json.dumps({'sourceRefName':'refs/heads/'+sys.argv[1],'targetRefName':'refs/heads/'+sys.argv[2],'title':sys.argv[3],'description':sys.argv[4]}))" \
                   "$branch" "$base_branch" "$title" "$description") || return 1
            _api_call "$auth" POST "$create_url" "$body" || return 1
            id=$(_json_eval "d['pullRequestId']") || return 1
            echo "  PR creado: https://dev.azure.com/$ADO_ORG/$ADO_PROJECT/_git/$ADO_REPO/pullrequest/$id"
            ;;

        gitlab)
            # Token: get_project_secret gitlab_token (scope: api).
            # El project ID se infiere del path URL-encoded del remoto origin.
            _require_deps || return 1
            local token gitlab_host project_path encoded_project existing_url create_url body url
            token="$(get_project_secret gitlab_token)" || return 1

            # Extraer host y path del remoto (soporta SSH y HTTPS)
            gitlab_host=$(echo "$origin_url" | sed -E 's#.*https?://([^/]+)/.*#\1#; s#.*git@([^:]+):.*#\1#')
            project_path=$(echo "$origin_url" | sed -E 's#.*https?://[^/]+/##; s#.*git@[^:]+:##; s#\.git$##')
            encoded_project=$("${PY_BIN:-python3}" -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$project_path") || return 1

            _api_call "PRIVATE-TOKEN: $token" GET \
                "https://$gitlab_host/api/v4/projects/$encoded_project/merge_requests?source_branch=${branch}&state=opened" "" || return 1
            existing_url=$(_json_eval "(d[0]['web_url'] if len(d) > 0 else '') if isinstance(d, list) else (_ for _ in ()).throw(TypeError('se esperaba una lista de MRs'))") || return 1

            if [ -n "$existing_url" ]; then
                echo "  MR existente actualizado: $existing_url"
                return 0
            fi

            create_url="https://$gitlab_host/api/v4/projects/$encoded_project/merge_requests"
            body=$("${PY_BIN:-python3}" -c "import json,sys; print(json.dumps({'source_branch':sys.argv[1],'target_branch':sys.argv[2],'title':sys.argv[3],'description':sys.argv[4]}))" \
                   "$branch" "$base_branch" "$title" "$description") || return 1
            _api_call "PRIVATE-TOKEN: $token" POST "$create_url" "$body" || return 1
            url=$(_json_eval "d['web_url']") || return 1
            echo "  MR creado: $url"
            ;;

        bitbucket)
            # No implementado. Devuelve error para que ship.sh NO reporte exito:
            # afirmar "PR creado" sin haberlo creado es peor que fallar.
            echo "  Bitbucket no esta implementado en este framework todavia." >&2
            echo "  Crea el PR manualmente, o implementa el caso siguiendo el patron de gitlab)." >&2
            echo "  Auth: Basic con usuario real + get_project_secret bitbucket_app_password." >&2
            return 1
            ;;

        *)
            echo "  Proveedor de git no reconocido ($origin_url). Crea el PR manualmente." >&2
            return 1
            ;;
    esac
}
