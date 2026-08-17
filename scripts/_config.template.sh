#!/usr/bin/env bash
# Configuracion compartida de los scripts operativos. Copiar a _config.sh en
# el proyecto real y rellenar. Se source-ea desde safety-check.sh y ship.sh.
#
# Credenciales: NUNCA hardcodear un valor real aca -- este archivo, una vez
# copiado, SI se trackea en git. Los secretos reales viven en un archivo
# gitignored (ver docs/03_architecture_patterns/secrets-management.md del
# framework) y se leen en runtime con get_project_secret().

# ============================================================================
# Deploy (opcional -- dejar vacio si el proyecto no tiene un paso scriptable)
# ============================================================================
DEPLOY_SCRIPT=""   # ej: "$SCRIPT_DIR/deploy.sh"

# ============================================================================
# Chequeo de "doc viva desincronizada" (safety-check.sh)
# ============================================================================
RISK_SIGNAL_PATTERNS=(
    'src/models/' 'src/api/auth\.' 'migrations/' 'src/services/'
)
DOC_FILES=(
    "AGENT_GUIDE.md" "CLAUDE.md"
    "Docs/03_governance_and_guidelines/architecture.md"
    "Docs/03_governance_and_guidelines/change-safety.md"
    "Docs/03_governance_and_guidelines/CHANGELOG.md"
)

# ============================================================================
# Git provider (ship.sh) -- ver docs en scripts/git-provider-pr.sh
# ============================================================================
# Se autodetecta por la URL del remoto 'origin'; solo hace falta llenar esto
# si el proveedor es Azure DevOps (necesita organization/project/repo
# explicitos, no se pueden inferir 100% de la URL SSH).
ADO_ORG=""
ADO_PROJECT=""
ADO_REPO=""

# Lee un secreto por nombre desde el archivo local gitignored. Falla con un error explicito
# si el archivo o la clave no existen -- nunca cae a un default silencioso.
# Requiere python3 (ver la seccion Dependencias de scripts/README.md).
get_project_secret() {
    local name="$1"
    local secrets_path
    secrets_path="$(git rev-parse --show-toplevel 2>/dev/null)/.local/secrets.json"
    if [ ! -f "$secrets_path" ]; then
        echo "ERROR: no encontre $secrets_path -- crearlo con el formato documentado en docs/03_architecture_patterns/secrets-management.md del framework." >&2
        return 1
    fi
    # Un traceback de Python no le dice a nadie que falta una clave: validarla aca y devolver
    # un mensaje que nombre la clave y el archivo.
    python3 -c '
import json, sys
path, key = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(path, encoding="utf-8"))
except Exception as e:
    sys.stderr.write("ERROR: %s no es JSON valido: %s\n" % (path, e))
    sys.exit(1)
secrets = data.get("secrets")
if not isinstance(secrets, dict):
    sys.stderr.write("ERROR: %s no tiene un objeto \"secrets\" en la raiz.\n" % path)
    sys.exit(1)
if key not in secrets or secrets[key] in (None, ""):
    sys.stderr.write("ERROR: la clave \"%s\" no existe (o esta vacia) en %s\n" % (key, path))
    sys.exit(1)
sys.stdout.write(str(secrets[key]))
' "$secrets_path" "$name"
}
