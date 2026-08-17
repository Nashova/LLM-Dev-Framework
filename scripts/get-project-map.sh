#!/usr/bin/env bash
# get-project-map.sh - Generador universal de mapa de estado para LLMs (Linux / macOS / WSL)
#
# Gemelo funcional de get-project-map.ps1: ramas activas, archivos sin commitear, ultimos
# commits, metricas de codigo por stack y puertos de Docker Compose.
#
# Uso: bash scripts/get-project-map.sh [ruta]
set -uo pipefail

ROOT_PATH="${1:-.}"
if [ ! -d "$ROOT_PATH" ]; then
    echo "Error: la ruta '$ROOT_PATH' no existe o no es un directorio" >&2
    exit 1
fi
ROOT_FULL="$(cd "$ROOT_PATH" && pwd)"
DATE_STR="$(date +'%Y-%m-%d %H:%M')"

echo "================ MAPA DEL PROYECTO ================"
echo "Raiz: $ROOT_FULL   Fecha: $DATE_STR"
echo ""

check_repo() {
    local name="$1"
    local dir="$2"
    echo "--- $name ---"
    if [ -d "$dir/.git" ]; then
        (
            cd "$dir" || exit
            local branch dirty_count
            branch="$(git branch --show-current 2>/dev/null)"
            [ -z "$branch" ] && branch="(detached / sin rama)"
            echo "rama actual : $branch"

            dirty_count="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
            if [ "$dirty_count" -gt 0 ]; then
                echo "pendientes  : $dirty_count archivo(s) sin commitear"
                git status --short 2>/dev/null | head -n 6 | sed 's/^/   /'
                if [ "$dirty_count" -gt 6 ]; then
                    echo "   ... ($((dirty_count - 6)) mas)"
                fi
            else
                echo "pendientes  : limpio"
            fi

            echo "ultimos commits:"
            git log -n 3 --oneline 2>/dev/null | sed 's/^/   /'
        )
    fi
    echo ""
}

if [ -d "$ROOT_FULL/.git" ]; then
    check_repo "RAIZ" "$ROOT_FULL"
fi

for sub in "$ROOT_FULL"/*; do
    if [ -d "$sub/.git" ]; then
        check_repo "$(basename "$sub")" "$sub"
    fi
done

# ---------------------------------------------------------------------------
# Metricas de codigo
#
# Fuente primaria: `git ls-files`. Es instantaneo y ya respeta .gitignore, asi que nunca
# recorre node_modules / bin / obj / venv ni cuenta dependencias ajenas como codigo propio.
# Solo se cae a `find` si el directorio no es un repo git.
# ---------------------------------------------------------------------------
echo "--- Conteos y Metricas de Codigo ---"

ALL_FILES=""
if [ -d "$ROOT_FULL/.git" ]; then
    ALL_FILES="$(cd "$ROOT_FULL" && git ls-files 2>/dev/null)"
fi
if [ -z "$ALL_FILES" ]; then
    ALL_FILES="$(cd "$ROOT_FULL" && find . -type f \
        -not -path '*/.git/*' \
        -not -path '*/node_modules/*' -not -path '*/dist/*' -not -path '*/build/*' \
        -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/venv/*' \
        -not -path '*/__pycache__/*' -not -path '*/vendor/*' -not -path '*/target/*' \
        2>/dev/null | sed 's|^\./||')"
fi

# count_re <regex extendida> -- cuenta rutas que matchean, sin recorrer disco de nuevo.
# OJO: `grep -c` ya imprime 0 cuando no hay match, pero sale con codigo 1. Un `|| echo 0`
# aqui imprimiria DOS ceros y rompe toda comparacion aritmetica posterior.
count_re() {
    local n
    n="$(printf '%s\n' "$ALL_FILES" | grep -cE "$1" 2>/dev/null)" || n=0
    [ -z "$n" ] && n=0
    printf '%s' "$n"
}

# Ruby / Rails
rb_models=$(count_re 'app/models/.*\.rb$')
rb_controllers=$(count_re 'app/controllers/.*\.rb$')
rb_services=$(count_re 'app/services/.*\.rb$')
rb_specs=$(count_re '_spec\.rb$')
if [ "$rb_models" -gt 0 ] || [ "$rb_controllers" -gt 0 ]; then
    echo "  Ruby/Rails : $rb_models modelos, $rb_controllers controladores, $rb_services servicios, $rb_specs specs"
fi

# TypeScript / JavaScript / Angular / React / Vue / Svelte
ts_count=$(count_re '\.ts$')
tsx_count=$(count_re '\.tsx$')
js_count=$(count_re '\.js$')
jsx_count=$(count_re '\.jsx$')
vue_count=$(count_re '\.vue$')
svelte_count=$(count_re '\.svelte$')
html_count=$(count_re '\.html$')
if [ $((ts_count + tsx_count + js_count + jsx_count + vue_count + svelte_count)) -gt 0 ]; then
    parts=""
    [ "$ts_count" -gt 0 ]     && parts="$parts, $ts_count .ts"
    [ "$tsx_count" -gt 0 ]    && parts="$parts, $tsx_count .tsx"
    [ "$js_count" -gt 0 ]     && parts="$parts, $js_count .js"
    [ "$jsx_count" -gt 0 ]    && parts="$parts, $jsx_count .jsx"
    [ "$vue_count" -gt 0 ]    && parts="$parts, $vue_count .vue"
    [ "$svelte_count" -gt 0 ] && parts="$parts, $svelte_count .svelte"
    [ "$html_count" -gt 0 ]   && parts="$parts, $html_count .html"
    echo "  Frontend   : ${parts#, }"
fi

# Python
py_count=$(count_re '\.py$')
py_tests=$(count_re '(^|/)(test_[^/]*|[^/]*_test)\.py$')
if [ "$py_count" -gt 0 ]; then
    echo "  Python     : $py_count archivos .py (incluye $py_tests tests)"
fi

# .NET / C#
cs_count=$(count_re '\.cs$')
cs_tests="$(printf '%s\n' "$ALL_FILES" | grep -icE 'tests?/.*\.cs$' 2>/dev/null)" || cs_tests=0
if [ "$cs_count" -gt 0 ]; then
    echo "  .NET / C#  : $cs_count archivos .cs (incluye $cs_tests en carpetas de test)"
fi

# Go
go_count=$(count_re '\.go$')
go_tests=$(count_re '_test\.go$')
if [ "$go_count" -gt 0 ]; then
    echo "  Go         : $go_count archivos .go (incluye $go_tests tests)"
fi

# Java / Kotlin
java_count=$(count_re '\.java$')
kt_count=$(count_re '\.kt$')
if [ $((java_count + kt_count)) -gt 0 ]; then
    echo "  JVM        : $java_count archivos .java, $kt_count .kt"
fi

# PHP
php_count=$(count_re '\.php$')
[ "$php_count" -gt 0 ] && echo "  PHP        : $php_count archivos .php"

# Rust
rs_count=$(count_re '\.rs$')
[ "$rs_count" -gt 0 ] && echo "  Rust       : $rs_count archivos .rs"

# Swift
swift_count=$(count_re '\.swift$')
[ "$swift_count" -gt 0 ] && echo "  Swift      : $swift_count archivos .swift"

# SQL
sql_count=$(count_re '\.sql$')
[ "$sql_count" -gt 0 ] && echo "  SQL        : $sql_count archivos .sql"

# Scripts de operacion
sh_count=$(count_re '\.sh$')
ps1_count=$(count_re '\.ps1$')
if [ $((sh_count + ps1_count)) -gt 0 ]; then
    echo "  Scripts    : $sh_count .sh, $ps1_count .ps1"
fi

# Docs
md_count=$(count_re '\.md$')
echo "  Docs (.md) : $md_count documentos Markdown"
total_count="$(printf '%s\n' "$ALL_FILES" | grep -c . 2>/dev/null)" || total_count=0
echo "  TOTAL      : $total_count archivos considerados"

# Puertos Docker Compose
compose_files=$(printf '%s\n' "$ALL_FILES" | grep -E '(^|/)docker-compose[^/]*\.ya?ml$' 2>/dev/null || true)
if [ -n "$compose_files" ]; then
    echo ""
    echo "--- Puertos Mapeados (Docker Compose) ---"
    printf '%s\n' "$compose_files" | while IFS= read -r cf; do
        [ -z "$cf" ] && continue
        [ -f "$ROOT_FULL/$cf" ] || continue
        ports=$(grep -oE '"?[0-9]{2,5}:[0-9]{2,5}"?' "$ROOT_FULL/$cf" 2>/dev/null | tr -d '"' | paste -sd ", " -)
        if [ -n "$ports" ]; then
            echo "  $cf : $ports"
        fi
    done
fi

echo ""
echo "===================================================="
