#!/usr/bin/env bash
# Validaciones rapidas anti-rompimiento antes de commit/deploy. Cero side-effects.
# Generalizado a partir del safety-check de un proyecto real -- ver examples/case-study-admin-console.md.
# Exit 0 si todo OK, 1 si encuentra fallas bloqueantes.
#
# Uso: bash scripts/safety-check.sh [--quiet]
set -uo pipefail

QUIET=0
for arg in "$@"; do
    case "$arg" in
        --quiet|-q) QUIET=1 ;;
        -h|--help)  echo "Uso: bash scripts/safety-check.sh [--quiet]"; exit 0 ;;
        *)          echo "Error: flag no reconocido: $arg" >&2; exit 2 ;;
    esac
done
say() { [ "$QUIET" -eq 1 ] || echo "$@"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/_config.sh" ]; then
    # shellcheck source=_config.sh
    source "$SCRIPT_DIR/_config.sh"
elif [ -f "$SCRIPT_DIR/_config.template.sh" ]; then
    say "  !  _config.sh no existe -- usando _config.template.sh como fallback."
    say "     Copia _config.template.sh a _config.sh y ajusta las variables de tu proyecto."
    # shellcheck source=_config.template.sh
    source "$SCRIPT_DIR/_config.template.sh"
else
    say "  !  Ni _config.sh ni _config.template.sh existen. Chequeos de doc viva deshabilitados."
    RISK_SIGNAL_PATTERNS=()
    DOC_FILES=()
fi

# Con `set -u`, expandir un array vacio aborta el script en bash 3.2 (el que trae
# macOS de fabrica). Estas variables garantizan que siempre existan.
: "${RISK_SIGNAL_PATTERNS:=}"
: "${DOC_FILES:=}"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then echo "ERROR: no estoy en un repo git" >&2; exit 1; fi
cd "$REPO_ROOT"

failures=()

# ---------- Lista de archivos cambiados, a prueba de espacios y renombrados ----------
# NO usar `git status --porcelain | awk '{print $2}'`: rompe con rutas que tienen
# espacios (awk corta en el espacio) y con renombrados (`R old -> new` deja `old`).
# `git diff --name-only -z` + `ls-files --others -z` da rutas limpias, NUL-separadas.
CHANGED_FILES=()
while IFS= read -r -d '' f; do
    [ -n "$f" ] && CHANGED_FILES+=("$f")
done < <(
    { git diff --name-only -z HEAD 2>/dev/null || true
      git ls-files -z --others --exclude-standard 2>/dev/null || true; }
)

# ---------- 1. Line endings en *.sh tracked ----------
# No dependemos de `file(1)` (no siempre existe, y su salida incluye el nombre del
# archivo, asi que un archivo llamado "algo-CRLF.sh" daria un falso positivo).
# Buscamos el byte CR directamente.
sh_count=0
while IFS= read -r -d '' f; do
    [ -z "$f" ] && continue
    sh_count=$((sh_count + 1))
    if [ -f "$f" ] && LC_ALL=C grep -qU $'\r' "$f" 2>/dev/null; then
        failures+=("CRLF en $f (rompe containers Linux -- forzar LF, ver .gitattributes)")
    fi
done < <(git ls-files -z -- '*.sh')

# ---------- 2. Sintaxis de archivos modificados ----------
# TODO: adaptar al stack real -- mismo patron que safety-check.ps1: para
# cada lenguaje del proyecto, parsear (no compilar/buildear entero) los
# archivos modificados de ese tipo.
py_count=0
sh_syntax_count=0
for f in ${CHANGED_FILES[@]+"${CHANGED_FILES[@]}"}; do
    [ -f "$f" ] || continue
    case "$f" in
        *.py)
            if command -v python3 >/dev/null 2>&1; then
                py_count=$((py_count + 1))
                if ! out=$(python3 -c "import ast,sys; ast.parse(open(sys.argv[1],encoding='utf-8').read())" "$f" 2>&1); then
                    failures+=("SyntaxError en $f -> $(echo "$out" | tail -1)")
                fi
            fi
            ;;
        *.sh)
            sh_syntax_count=$((sh_syntax_count + 1))
            if ! out=$(bash -n "$f" 2>&1); then
                failures+=("Error de sintaxis en $f -> $(echo "$out" | tail -1)")
            fi
            ;;
    esac
done

# ---------- 3. Documentacion viva desincronizada (no bloqueante) ----------
touched_signal=false
for pattern in ${RISK_SIGNAL_PATTERNS[@]+"${RISK_SIGNAL_PATTERNS[@]}"}; do
    [ -z "$pattern" ] && continue
    for f in ${CHANGED_FILES[@]+"${CHANGED_FILES[@]}"}; do
        if printf '%s' "$f" | grep -qE "$pattern"; then touched_signal=true; break 2; fi
    done
done
touched_docs=false
for doc in ${DOC_FILES[@]+"${DOC_FILES[@]}"}; do
    [ -z "$doc" ] && continue
    for f in ${CHANGED_FILES[@]+"${CHANGED_FILES[@]}"}; do
        if [ "$f" = "$doc" ]; then touched_docs=true; break 2; fi
    done
done

if [ "$touched_signal" = true ] && [ "$touched_docs" = false ]; then
    say ""
    say "  !  Aviso: tocaste archivos de riesgo sin tocar ninguna doc viva"
    say "     (${DOC_FILES[*]-})."
    say "     Si el cambio agrega/cambia una regla de negocio o decision operativa, actualiza la doc"
    say "     correspondiente en el mismo commit. Si es un fix menor sin impacto de diseno, ignora este aviso."
fi

# ---------- 4. Resumen ----------
if [ ${#failures[@]} -gt 0 ]; then
    echo ""
    echo "  X  Safety check FAILED"
    for f in "${failures[@]}"; do echo "     - $f"; done
    echo ""
    exit 1
fi

say "  OK  Safety check ($sh_count .sh tracked, $py_count .py y $sh_syntax_count .sh modificados)"
exit 0
