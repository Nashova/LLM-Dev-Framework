#!/usr/bin/env bash
# bootstrap-ai.sh - Inicializador universal de conectividad Multi-IA (Linux / macOS / WSL)
#
# Gemelo funcional de bootstrap-ai.ps1. Genera los puntos de entrada de cada herramienta de IA
# a partir de AGENT_GUIDE.md.
#
# SEGURIDAD: nunca sobrescribe un archivo que no haya generado el mismo. Si encuentra un
# CLAUDE.md/.cursorrules/etc. escrito a mano, lo deja intacto y avisa. Con --force lo respalda
# como <archivo>.bak antes de reemplazarlo.
#
# ENLACES RELATIVOS: los destinos que viven en un subdirectorio (.github/copilot-instructions.md)
# reciben los enlaces de AGENT_GUIDE.md reescritos con el '../' que corresponde a su profundidad.
# Los destinos en la raiz se copian sin tocar.
#
# Uso: bash scripts/bootstrap-ai.sh [ruta] [--force] [--dry-run]

set -euo pipefail

TARGET_DIR="."
FORCE=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            echo "Uso: bash scripts/bootstrap-ai.sh [ruta] [--force] [--dry-run]"
            exit 0 ;;
        -*)
            echo "Error: flag no reconocido: $arg" >&2
            exit 2 ;;
        *)         TARGET_DIR="$arg" ;;
    esac
done

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: la ruta '$TARGET_DIR' no existe o no es un directorio" >&2
    exit 1
fi

ROOT_FULL="$(cd "$TARGET_DIR" && pwd)"
SOURCE_GUIDE="$ROOT_FULL/AGENT_GUIDE.md"

if [ ! -f "$SOURCE_GUIDE" ]; then
    echo "Error: No se encontro AGENT_GUIDE.md en $ROOT_FULL" >&2
    echo "  bootstrap-ai se corre desde la raiz de TU proyecto, con tu AGENT_GUIDE.md ya copiado ahi." >&2
    exit 1
fi

MARKER='<!-- ARCHIVO AUTOGENERADO DESDE AGENT_GUIDE.md - NO EDITAR DIRECTAMENTE -->'

echo "--- Sincronizando Configuracion Multi-IA ---"
echo "Fuente de verdad: $SOURCE_GUIDE"
[ "$DRY_RUN" -eq 1 ] && echo "MODO DRY-RUN: no se escribe ningun archivo."
echo ""

WRITTEN=0
SKIPPED=0
BACKED=0

# Reescribe los enlaces relativos de Markdown para un destino que vive N niveles
# por debajo de la raiz del proyecto. Sin esto, un archivo generado en un
# subdirectorio (el caso real: .github/copilot-instructions.md) hereda los enlaces
# de AGENT_GUIDE.md tal cual, y todos apuntan a un nivel que ya no existe desde ahi.
#
# Se reescribe solo lo que es una ruta relativa de verdad: el patron exige que el
# destino empiece con letra/digito/punto/guion-bajo (excluye anclas '#...' y rutas
# absolutas '/...') y que NO contenga ':' (excluye 'https://', 'mailto:',
# 'obsidian://' y rutas tipo 'C:\...').
rewrite_relative_links() {
    local depth="$1"
    local prefix=""
    local i
    for (( i = 0; i < depth; i++ )); do
        prefix="../$prefix"
    done
    if [ -z "$prefix" ]; then
        cat
    else
        sed -E "s#\]\(([A-Za-z0-9_.][^):]*)\)#](${prefix}\1)#g"
    fi
}

sync_file() {
    local name="$1"
    local dest="$2"
    local leaf
    leaf="$(basename "$dest")"

    # Profundidad del destino respecto a la raiz: cuantos '/' tiene su ruta relativa.
    local rel depth
    rel="${dest#"$ROOT_FULL"/}"
    depth="$(printf '%s' "$rel" | tr -cd '/' | wc -c | tr -d ' ')"

    if [ -f "$dest" ]; then
        # ¿La primera linea es nuestro marcador? Entonces es una resincronizacion legitima.
        if [ "$(head -n 1 "$dest")" != "$MARKER" ]; then
            if [ "$FORCE" -eq 0 ]; then
                echo "  [OMITIDO] $name -> $leaf ya existe y NO fue generado por este script."
                echo "            No se toco. Usa --force para respaldarlo como ${leaf}.bak y reemplazarlo."
                SKIPPED=$((SKIPPED + 1))
                return 0
            fi
            [ "$DRY_RUN" -eq 0 ] && cp -f "$dest" "${dest}.bak"
            echo "  [RESPALDO] $leaf -> ${leaf}.bak"
            BACKED=$((BACKED + 1))
        fi
    fi

    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$dest")"
        { printf '%s\n\n' "$MARKER"; rewrite_relative_links "$depth" < "$SOURCE_GUIDE"; } > "$dest"
    fi
    if [ "$depth" -gt 0 ]; then
        echo "  [OK] $name -> $leaf (enlaces relativos ajustados $depth nivel(es))"
    else
        echo "  [OK] $name -> $leaf"
    fi
    WRITTEN=$((WRITTEN + 1))
}

# AGENTS.md va en la raiz: es la convencion emergente multi-herramienta que documenta
# AGENT_GUIDE.md, no un subdirectorio propio.
sync_file "Claude Code"             "$ROOT_FULL/CLAUDE.md"
sync_file "Antigravity / Gemini"    "$ROOT_FULL/GEMINI.md"
sync_file "Convencion multi-agente" "$ROOT_FULL/AGENTS.md"
sync_file "Cursor Rules"            "$ROOT_FULL/.cursorrules"
sync_file "Windsurf Rules"          "$ROOT_FULL/.windsurfrules"
sync_file "GitHub Copilot"          "$ROOT_FULL/.github/copilot-instructions.md"

echo ""
echo "Resumen: $WRITTEN generados, $SKIPPED omitidos, $BACKED respaldados."
if [ "$SKIPPED" -gt 0 ]; then
    echo "Hubo archivos preexistentes que se dejaron intactos. Revisa la lista de arriba."
fi
