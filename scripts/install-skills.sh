#!/usr/bin/env bash
# install-skills.sh - Instala las skills del framework en el formato nativo de cada herramienta de IA.
#
# Una skill se escribe UNA vez como skills/<nombre>/SKILL.md (formato Agent Skills: frontmatter
# con name + description). Este script la traduce al formato que cada herramienta espera, para no
# mantener seis copias divergentes a mano.
#
# SEGURIDAD: nunca sobrescribe un archivo que no haya generado el mismo (mismo criterio que
# bootstrap-ai). Con --force lo respalda como <archivo>.bak antes de reemplazarlo.
#
# Uso:
#   bash scripts/install-skills.sh --target <dir> [--tool <t>] [--skills a,b] [--dry-run] [--force]
#
#   --target   Raiz del proyecto destino (default: directorio actual).
#   --tool     claude | cursor | copilot | windsurf | gemini | codex | continue | generic | all
#              (default: claude). "generic" produce un solo LLM_PLAYBOOK.md, que es la via para
#              cualquier herramienta o modelo local sin soporte nativo de skills.
#   --skills   Lista separada por comas. Default: todas.
#   --list     Lista las skills disponibles y sale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(cd "$SCRIPT_DIR/../skills" 2>/dev/null && pwd || true)"

TARGET="."
TOOL="claude"
ONLY_SKILLS=""
DRY_RUN=0
FORCE=0
DO_LIST=0

while [ $# -gt 0 ]; do
    case "$1" in
        --target)  TARGET="$2"; shift 2 ;;
        --tool)    TOOL="$2"; shift 2 ;;
        --skills)  ONLY_SKILLS="$2"; shift 2 ;;
        --dry-run) DRY_RUN=1; shift ;;
        --force)   FORCE=1; shift ;;
        --list)    DO_LIST=1; shift ;;
        -h|--help) sed -n '2,25p' "${BASH_SOURCE[0]}"; exit 0 ;;
        *) echo "Error: argumento no reconocido: $1" >&2; exit 2 ;;
    esac
done

if [ -z "$SKILLS_DIR" ] || [ ! -d "$SKILLS_DIR" ]; then
    echo "ERROR: no encontre el directorio skills/ junto a scripts/." >&2
    echo "  Corré este script desde el repo del framework." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Descubrimiento y parseo de skills
# ---------------------------------------------------------------------------
list_skills() {
    for d in "$SKILLS_DIR"/*/; do
        [ -f "$d/SKILL.md" ] || continue
        basename "$d"
    done | sort
}

# skill_field <archivo> <campo> -- lee un campo del frontmatter YAML.
skill_field() {
    awk -v want="$2" '
        NR == 1 && $0 == "---" { infm = 1; next }
        infm && $0 == "---"    { exit }
        infm {
            idx = index($0, ":")
            if (idx > 0) {
                key = substr($0, 1, idx - 1)
                val = substr($0, idx + 1)
                gsub(/^[ \t]+|[ \t]+$/, "", key)
                gsub(/^[ \t]+|[ \t]+$/, "", val)
                if (key == want) { print val; exit }
            }
        }
    ' "$1"
}

# skill_body <archivo> -- todo lo que sigue al cierre del frontmatter.
skill_body() {
    awk '
        NR == 1 && $0 == "---" { infm = 1; next }
        infm && $0 == "---"    { infm = 0; started = 1; next }
        started { print }
        !infm && !started      { print }
    ' "$1"
}

if [ "$DO_LIST" -eq 1 ]; then
    echo "Skills disponibles en $SKILLS_DIR:"
    while IFS= read -r s; do
        printf '  %-24s %s\n' "$s" "$(skill_field "$SKILLS_DIR/$s/SKILL.md" description | cut -c1-90)"
    done < <(list_skills)
    exit 0
fi

if [ ! -d "$TARGET" ]; then
    echo "ERROR: el directorio destino '$TARGET' no existe." >&2
    exit 1
fi
TARGET="$(cd "$TARGET" && pwd)"

SELECTED=()
if [ -n "$ONLY_SKILLS" ]; then
    IFS=',' read -r -a requested <<< "$ONLY_SKILLS"
    for r in "${requested[@]}"; do
        r="$(echo "$r" | tr -d ' ')"
        if [ -f "$SKILLS_DIR/$r/SKILL.md" ]; then
            SELECTED+=("$r")
        else
            echo "ERROR: la skill '$r' no existe. Corré --list para ver las disponibles." >&2
            exit 1
        fi
    done
else
    while IFS= read -r s; do SELECTED+=("$s"); done < <(list_skills)
fi

MARKER="<!-- GENERADO POR install-skills DESDE skills/<nombre>/SKILL.md - NO EDITAR DIRECTAMENTE -->"

WRITTEN=0
SKIPPED=0
BACKED=0

# write_guarded <destino> <contenido>
write_guarded() {
    local dest="$1" content="$2" leaf
    leaf="$(basename "$dest")"

    # Se busca el marcador en TODO el archivo, no solo en el encabezado: en el formato de Claude
    # va al final (el frontmatter tiene que ser la primera linea) y en los demas va tras el cierre
    # del frontmatter. Limitar la busqueda a las primeras lineas haria que una segunda corrida
    # tratara sus propios archivos como ajenos.
    if [ -f "$dest" ] && ! grep -qF "GENERADO POR install-skills" "$dest"; then
        if [ "$FORCE" -eq 0 ]; then
            echo "  [OMITIDO] $leaf ya existe y no lo generó este script. Usá --force para reemplazarlo."
            SKIPPED=$((SKIPPED + 1))
            return 0
        fi
        [ "$DRY_RUN" -eq 0 ] && cp -f "$dest" "${dest}.bak"
        echo "  [RESPALDO] $leaf -> ${leaf}.bak"
        BACKED=$((BACKED + 1))
    fi

    if [ "$DRY_RUN" -eq 0 ]; then
        mkdir -p "$(dirname "$dest")"
        printf '%s\n' "$content" > "$dest"
    fi
    echo "  [OK] ${dest#$TARGET/}"
    WRITTEN=$((WRITTEN + 1))
}

emit_claude() {
    local name="$1" src="$2"
    local dest="$TARGET/.claude/skills/$name/SKILL.md"
    # Claude Code consume el formato nativo: se copia tal cual, con el marcador al final
    # para no romper el frontmatter, que debe seguir siendo la primera linea.
    write_guarded "$dest" "$(cat "$src")

$MARKER"
}

# El frontmatter YAML tiene que ser lo PRIMERO del archivo: un comentario HTML antes del `---`
# lo invalida y la herramienta deja de reconocer la regla. El marcador va despues del cierre.
#
# yaml_str <texto> -- emite un escalar YAML de doble comilla, escapando `\` y `"`. Sin esto, una
# description que contenga `: ` o empiece con una comilla rompe el parseo.
yaml_str() {
    printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
}

emit_cursor() {
    local name="$1" src="$2" desc body
    desc="$(yaml_str "$(skill_field "$src" description)")"
    body="$(skill_body "$src")"
    write_guarded "$TARGET/.cursor/rules/$name.mdc" "---
description: $desc
alwaysApply: false
---
$MARKER
$body"
}

emit_copilot() {
    local name="$1" src="$2" desc body
    desc="$(yaml_str "$(skill_field "$src" description)")"
    body="$(skill_body "$src")"
    write_guarded "$TARGET/.github/instructions/$name.instructions.md" "---
applyTo: '**'
description: $desc
---
$MARKER
$body"
}

emit_windsurf() {
    local name="$1" src="$2" desc body
    desc="$(yaml_str "$(skill_field "$src" description)")"
    body="$(skill_body "$src")"
    write_guarded "$TARGET/.windsurf/rules/$name.md" "---
trigger: model_decision
description: $desc
---
$MARKER
$body"
}

emit_continue() {
    local name="$1" src="$2" desc body
    desc="$(yaml_str "$(skill_field "$src" description)")"
    body="$(skill_body "$src")"
    write_guarded "$TARGET/.continue/rules/$name.md" "---
name: $name
description: $desc
---
$MARKER
$body"
}

# Herramientas de un solo archivo (Gemini CLI, Codex/AGENTS.md, aider, cualquier modelo local):
# se concatena todo en un playbook con tabla de ruteo al principio.
emit_playbook() {
    local dest="$1"
    local content="$MARKER

# Playbook de skills — $(basename "$TARGET")

Este archivo concentra las skills del framework para herramientas que no tienen soporte nativo de
skills. **Cómo usarlo**: leé la tabla de ruteo, identificá si la tarea actual encaja en alguna fila y,
si encaja, leé esa sección completa antes de actuar. Si ninguna aplica, seguí normalmente.

## Tabla de ruteo

| Si la tarea es... | Leé la sección |
|---|---|"

    local name desc
    for name in "${SELECTED[@]}"; do
        desc="$(skill_field "$SKILLS_DIR/$name/SKILL.md" description)"
        content="$content
| ${desc:0:150} | [$name](#$name) |"
    done

    for name in "${SELECTED[@]}"; do
        content="$content

---

<a id=\"$name\"></a>

# $name

$(skill_body "$SKILLS_DIR/$name/SKILL.md")"
    done

    write_guarded "$dest" "$content"
}

install_for_tool() {
    local tool="$1" name
    echo ""
    echo "--- $tool ---"
    case "$tool" in
        claude)   for name in "${SELECTED[@]}"; do emit_claude   "$name" "$SKILLS_DIR/$name/SKILL.md"; done ;;
        cursor)   for name in "${SELECTED[@]}"; do emit_cursor   "$name" "$SKILLS_DIR/$name/SKILL.md"; done ;;
        copilot)  for name in "${SELECTED[@]}"; do emit_copilot  "$name" "$SKILLS_DIR/$name/SKILL.md"; done ;;
        windsurf) for name in "${SELECTED[@]}"; do emit_windsurf "$name" "$SKILLS_DIR/$name/SKILL.md"; done ;;
        continue) for name in "${SELECTED[@]}"; do emit_continue "$name" "$SKILLS_DIR/$name/SKILL.md"; done ;;
        gemini)
            emit_playbook "$TARGET/.gemini/skills-playbook.md"
            echo "  NOTA: agregá a tu GEMINI.md la linea:  @.gemini/skills-playbook.md"
            ;;
        codex)
            emit_playbook "$TARGET/.agent-skills-playbook.md"
            echo "  NOTA: referenciá el playbook desde tu AGENTS.md."
            ;;
        generic)
            emit_playbook "$TARGET/LLM_PLAYBOOK.md"
            echo "  NOTA: pegá este archivo como system prompt, o pasalo como contexto al modelo local."
            ;;
        *)
            echo "ERROR: herramienta no reconocida: $tool" >&2
            echo "  Validas: claude cursor copilot windsurf gemini codex continue generic all" >&2
            exit 2
            ;;
    esac
}

echo "--- Instalando skills del framework ---"
echo "Origen  : $SKILLS_DIR"
echo "Destino : $TARGET"
echo "Skills  : ${#SELECTED[@]} (${SELECTED[*]})"
[ "$DRY_RUN" -eq 1 ] && echo "MODO DRY-RUN: no se escribe nada."

if [ "$TOOL" = "all" ]; then
    for t in claude cursor copilot windsurf continue gemini codex generic; do
        install_for_tool "$t"
    done
else
    install_for_tool "$TOOL"
fi

echo ""
echo "Resumen: $WRITTEN escritos, $SKIPPED omitidos, $BACKED respaldados."
if [ "$SKIPPED" -gt 0 ]; then
    echo "Hubo archivos preexistentes que se dejaron intactos. Revisá la lista de arriba."
fi
