#!/usr/bin/env bash
# get-project-map.sh - Generador universal de mapa de estado para LLMs (Linux / macOS / WSL)

ROOT_PATH="${1:-.}"
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
        cd "$dir" || return
        local branch
        branch="$(git branch --show-current 2>/dev/null || echo "(sin rama)")"
        echo "rama actual : $branch"
        
        local dirty_count
        dirty_count="$(git status --short 2>/dev/null | wc -l)"
        if [ "$dirty_count" -gt 0 ]; then
            echo "pendientes  : $dirty_count archivo(s) sin commitear"
            git status --short 2>/dev/null | head -n 6
        else
            echo "pendientes  : limpio"
        fi
        
        echo "ultimos commits:"
        git log -n 3 --oneline 2>/dev/null | sed 's/^/   /'
        cd - >/dev/null || return
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

echo "--- Conteos y Metricas de Codigo ---"

# Ruby / Rails
rb_models=$(find "$ROOT_FULL" -name "*.rb" -path "*/app/models/*" 2>/dev/null | wc -l)
rb_controllers=$(find "$ROOT_FULL" -name "*.rb" -path "*/app/controllers/*" 2>/dev/null | wc -l)
rb_services=$(find "$ROOT_FULL" -name "*.rb" -path "*/app/services/*" 2>/dev/null | wc -l)
rb_specs=$(find "$ROOT_FULL" -name "*_spec.rb" 2>/dev/null | wc -l)
if [ "$rb_models" -gt 0 ] || [ "$rb_controllers" -gt 0 ]; then
    echo "  Ruby/Rails : $rb_models modelos, $rb_controllers controladores, $rb_services servicios, $rb_specs specs"
fi

# TypeScript / Angular / React / Vue
ts_count=$(find "$ROOT_FULL" -name "*.ts" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | wc -l)
tsx_count=$(find "$ROOT_FULL" -name "*.tsx" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | wc -l)
html_count=$(find "$ROOT_FULL" -name "*.html" -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/build/*" 2>/dev/null | wc -l)
if [ "$ts_count" -gt 0 ] || [ "$tsx_count" -gt 0 ]; then
    echo "  Frontend   : $ts_count archivos .ts, $tsx_count archivos .tsx, $html_count plantillas .html"
fi

# Python / FastAPI / Django / Flask
py_count=$(find "$ROOT_FULL" -name "*.py" -not -path "*/venv/*" -not -path "*/ENV/*" -not -path "*/__pycache__/*" 2>/dev/null | wc -l)
py_tests=$(find "$ROOT_FULL" -name "test_*.py" -not -path "*/venv/*" -not -path "*/ENV/*" 2>/dev/null | wc -l)
if [ "$py_count" -gt 0 ]; then
    echo "  Python     : $py_count archivos .py (incluye $py_tests tests)"
fi

# .NET / C#
cs_count=$(find "$ROOT_FULL" -name "*.cs" -not -path "*/bin/*" -not -path "*/obj/*" 2>/dev/null | wc -l)
if [ "$cs_count" -gt 0 ]; then
    echo "  .NET / C#  : $cs_count archivos de codigo .cs"
fi

# Docs
md_count=$(find "$ROOT_FULL" -name "*.md" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | wc -l)
echo "  Docs (.md) : $md_count documentos Markdown"

# Puertos Docker Compose
compose_files=$(find "$ROOT_FULL" -name "docker-compose*.yml" 2>/dev/null)
if [ -n "$compose_files" ]; then
    echo ""
    echo "--- Puertos Mapeados (Docker Compose) ---"
    echo "$compose_files" | while IFS= read -r cf; do
        rel_path="${cf#$ROOT_FULL/}"
        ports=$(grep -oE '"?[0-9]{2,5}:[0-9]{2,5}"?' "$cf" 2>/dev/null | tr -d '"' | paste -sd ", " -)
        if [ -n "$ports" ]; then
            echo "  $rel_path : $ports"
        fi
    done
fi

echo ""
echo "===================================================="

