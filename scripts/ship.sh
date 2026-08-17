#!/usr/bin/env bash
# Flujo completo: safety-check -> commit -> [deploy] -> push -> PR.
# Generalizado a partir del ship.ps1 de un proyecto real. Ver ship.ps1 para la doc completa
# (misma logica, misma flags).
#
# Uso:
#   ./ship.sh -m "mensaje" [--deploy] [--no-pr] [--base main]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Con `set -e`, un `source` de un archivo inexistente muere con un mensaje cripitco de bash.
# Un error explicito ahorra la sesion de debugging que eso provoca en un clon nuevo.
if [ ! -f "$SCRIPT_DIR/_config.sh" ]; then
    echo "ERROR: falta $SCRIPT_DIR/_config.sh" >&2
    echo "  Copia la plantilla y ajusta las variables de tu proyecto:" >&2
    echo "    cp \"$SCRIPT_DIR/_config.template.sh\" \"$SCRIPT_DIR/_config.sh\"" >&2
    echo "  Ver scripts/README.md del framework." >&2
    exit 1
fi
source "$SCRIPT_DIR/_config.sh"
source "$SCRIPT_DIR/git-provider-pr.sh"

MESSAGE=""
DO_DEPLOY=false
NO_PR=false
BASE_BRANCH="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--message) MESSAGE="$2"; shift 2 ;;
        --deploy) DO_DEPLOY=true; shift ;;
        --no-pr) NO_PR=true; shift ;;
        --base) BASE_BRANCH="$2"; shift 2 ;;
        *) echo "Argumento desconocido: $1" >&2; exit 1 ;;
    esac
done

if [ -z "$MESSAGE" ]; then
    echo "Uso: ./ship.sh -m \"mensaje\" [--deploy] [--no-pr] [--base main]" >&2
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

echo ""
echo "[1/5] Safety check..."
if ! "$SCRIPT_DIR/safety-check.sh"; then
    echo "Abortando: arregla los problemas y volve a correr." >&2
    exit 1
fi

if [ -z "$(git status --porcelain)" ]; then
    echo ""
    echo "Nada que commitear. Working tree limpio."
    exit 0
fi

echo ""
echo "[2/5] Commit..."
git add -A
git commit -m "$MESSAGE"

if [ "$DO_DEPLOY" = true ] && [ -n "${DEPLOY_SCRIPT:-}" ] && [ -f "$DEPLOY_SCRIPT" ]; then
    echo ""
    echo "[3/5] Deploy..."
    "$DEPLOY_SCRIPT"
else
    echo ""
    echo "[3/5] (deploy salteado)"
fi

BRANCH="$(git branch --show-current)"
echo ""
echo "[4/5] Push de $BRANCH..."
git push -u origin "$BRANCH"

if [ "$NO_PR" = true ]; then
    echo ""
    echo "[5/5] PR salteado (--no-pr)"
    exit 0
fi

echo ""
echo "[5/5] Creando/verificando PR..."
# printf, no echo: `echo` interpreta -n/-e y secuencias de backslash, asi que un mensaje
# de commit que empiece con "-e" o contenga "\n" saldria mutilado en el titulo del PR.
TITLE="$(printf '%s\n' "$MESSAGE" | head -1)"
new_or_update_pull_request "$BRANCH" "$BASE_BRANCH" "$TITLE" "$MESSAGE"
