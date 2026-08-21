#!/usr/bin/env bash
# validate-knowledge-base.sh - Validador universal de citas en la documentacion (Linux / macOS)
#
# Verifica que toda ruta de archivo citada entre backticks exista de verdad, para que la
# documentacion no mienta. Una cita se busca, en este orden:
#   1. Relativa al documento que la cita  (docs/guia.md citando ../src/app.py)
#   2. Relativa a la raiz del proyecto
#   3. En subdirectorios de primer nivel, y en sus src/ y app/ (submodulos, monorepos)
#   4. En los repos externos declarados en KB_EXTERNAL_ROOTS de _config.sh
#
# KB_EXTERNAL_ROOTS existe para el caso real de un proyecto cuya documentacion cita a proposito
# archivos de OTRO repo (tipicamente este framework: "ver docs/03_architecture_patterns/xxx.md del
# framework"). Esas citas no estan rotas -- viven en otro repo -- pero tampoco deberian ignorarse
# a ciegas. Declarando el repo hermano se verifican de verdad contra el disco.
#
# Uso: bash scripts/validate-knowledge-base.sh [DOCS_PATH] [PROJECT_ROOT]
#      DOCS_PATH default "docs". Si tu proyecto usa "Docs/" (la convencion de
#      new-project-checklist.md), pasalo explicitamente: bash scripts/validate-knowledge-base.sh Docs

DOCS_PATH="${1:-docs}"
PROJECT_ROOT="${2:-.}"
ROOT_FULL="$(cd "$PROJECT_ROOT" && pwd)"
DOCS_FULL="$(cd "$ROOT_FULL/$DOCS_PATH" 2>/dev/null && pwd)"

if [ -z "$DOCS_FULL" ] || [ ! -d "$DOCS_FULL" ]; then
    echo "Error: No se encontro el directorio de documentacion en $ROOT_FULL/$DOCS_PATH"
    exit 1
fi

# Repos externos contra los que tambien se resuelven las citas (rutas relativas a la raiz del
# proyecto, ej. "../LLM-Dev-Framework"). Si _config.sh no existe o no los define, queda vacio.
KB_EXTERNAL_ROOTS=()
if [ -f "$(dirname "${BASH_SOURCE[0]}")/_config.sh" ]; then
    # shellcheck disable=SC1090
    . "$(dirname "${BASH_SOURCE[0]}")/_config.sh"
fi

# Lista blanca de extensiones -- la misma que usa el gemelo .ps1. Sin ella, cualquier mencion en
# prosa de un archivo de runtime (.git/index.lock, un .tmp, un .bak) se contaria como cita de
# documentacion y se reportaria como rota.
EXT_RE='(rb|ts|tsx|js|jsx|cs|py|go|rs|java|yml|yaml|json|sql|md|rake|ps1|sh|html|scss|css)'

echo "--- Validando Citas de Codigo en Base de Conocimiento ---"
echo "Raiz del Proyecto: $ROOT_FULL"
echo "Directorio Docs  : $DOCS_FULL"
if [ ${#KB_EXTERNAL_ROOTS[@]} -gt 0 ]; then
    echo "Repos externos   : ${KB_EXTERNAL_ROOTS[*]}"
fi
echo ""

checked=0
broken=0

while IFS= read -r doc; do
    doc_dir="$(dirname "$doc")"

    # Un solo paso por ARCHIVO, no por linea. La version original lanzaba dos subprocesos
    # (echo | grep) por cada linea de cada documento -- sobre una base de conocimiento normal
    # son varios miles de forks, y en Git Bash para Windows eso convierte una corrida de
    # ~2 segundos en una de varios minutos, al punto de volver inusable un script que se
    # supone corre antes de cada PR. Filtrar y extraer en una sola pasada da el mismo
    # resultado (mismo conteo, mismo orden, sin deduplicar) a una fraccion del costo.
    matches=$(grep -vE '\(nuevo|\(propuesto|\(template|\(ejemplo|\(generado' "$doc" \
              | grep -oE "\`[A-Za-z0-9_./\\-]+\.$EXT_RE(:[0-9-]+)?\`" \
              | tr -d '`' | cut -d: -f1)

    for cite in $matches; do
        # Solo validar si contiene separador de ruta
        if [[ "$cite" == *"/"* ]] || [[ "$cite" == *"\\"* ]]; then
            ((checked++))
            found=0

            # 1) Relativa al documento que cita   2) relativa a la raiz del proyecto
            if [ -e "$doc_dir/$cite" ] || [ -e "$ROOT_FULL/$cite" ]; then
                found=1
            fi

            # 3) Subdirectorios de primer nivel (submodulos, src/, app/)
            if [ "$found" -eq 0 ]; then
                for sub in "$ROOT_FULL"/*; do
                    if [ -e "$sub/$cite" ] || [ -e "$sub/src/$cite" ] || [ -e "$sub/app/$cite" ]; then
                        found=1
                        break
                    fi
                done
            fi

            # 4) Repos externos declarados en _config.sh
            if [ "$found" -eq 0 ] && [ ${#KB_EXTERNAL_ROOTS[@]} -gt 0 ]; then
                for ext in "${KB_EXTERNAL_ROOTS[@]}"; do
                    ext_full="$(cd "$ROOT_FULL/$ext" 2>/dev/null && pwd)"
                    [ -z "$ext_full" ] && continue
                    if [ -e "$ext_full/$cite" ]; then
                        found=1
                        break
                    fi
                done
            fi

            if [ "$found" -eq 0 ]; then
                rel_doc="${doc#$ROOT_FULL/}"
                echo "  [ROTA] $rel_doc cita: $cite"
                ((broken++))
            fi
        fi
    done
done < <(find "$DOCS_FULL" -name "*.md" -type f)

echo ""
echo "Citas revisadas: $checked   Rotas: $broken"
if [ "$broken" -eq 0 ]; then
    echo "Base de Conocimiento 100% consistente con el codigo."
    exit 0
else
    echo "Error: Existen citas rotas. Actualizar los documentos marcados."
    exit 1
fi
