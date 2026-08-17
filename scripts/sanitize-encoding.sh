#!/usr/bin/env bash
# sanitize-encoding.sh - Limpieza universal de caracteres no validos y normalizacion UTF-8
#
# Gemelo funcional de sanitize-encoding.ps1. Remueve caracteres de control prohibidos en XML
# (\x00-\x08, \x0B-\x0C, \x0E-\x1F) de archivos de texto ya codificados en UTF-8.
#
# SEGURIDAD:
#   - Solo toca archivos que YA son UTF-8 valido. Un archivo en Latin-1/Windows-1252 se OMITE
#     con aviso, nunca se reescribe: decodificarlo como UTF-8 lo llenaria de U+FFFD y destruiria
#     los bytes originales de forma irreversible.
#   - --dry-run reporta que cambiaria sin escribir nada. Correlo primero.
#   - Con --backup deja un <archivo>.bak antes de reescribir.
#
# Dependencia: python3 (ver la seccion Requisitos del README del framework).
#
# Uso: bash scripts/sanitize-encoding.sh [ruta] [--dry-run] [--backup]

set -euo pipefail

TARGET="."
DRY_RUN=0
BACKUP=0

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=1 ;;
        --backup)  BACKUP=1 ;;
        -h|--help)
            echo "Uso: bash scripts/sanitize-encoding.sh [ruta] [--dry-run] [--backup]"
            exit 0 ;;
        -*)
            echo "Error: flag no reconocido: $arg" >&2
            exit 2 ;;
        *)         TARGET="$arg" ;;
    esac
done

# En Windows, `command -v python3` puede resolver al App Execution Alias de la Microsoft Store,
# que existe pero no ejecuta nada. No basta con que el binario este en el PATH: hay que
# comprobar que efectivamente corra.
resolve_python() {
    local candidate
    for candidate in python3 python; do
        if command -v "$candidate" >/dev/null 2>&1 && "$candidate" -c 'pass' >/dev/null 2>&1; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

if ! PY_BIN="$(resolve_python)"; then
    echo "Error: sanitize-encoding.sh requiere un python3 funcional en el PATH." >&2
    echo "  En Windows, usa la version PowerShell: scripts/sanitize-encoding.ps1" >&2
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "Error: la ruta '$TARGET' no existe o no es un directorio" >&2
    exit 1
fi

TARGET_FULL="$(cd "$TARGET" && pwd)"

echo "--- Limpieza y Normalizacion UTF-8 ---"
echo "Ruta: $TARGET_FULL"
[ "$DRY_RUN" -eq 1 ] && echo "MODO DRY-RUN: no se escribe ningun archivo."
echo ""

DRY_RUN="$DRY_RUN" BACKUP="$BACKUP" "$PY_BIN" - "$TARGET_FULL" <<'PY'
import os, re, shutil, sys

root     = sys.argv[1]
dry_run  = os.environ.get("DRY_RUN") == "1"
backup   = os.environ.get("BACKUP") == "1"

EXTS    = (".md", ".ps1", ".sh", ".txt", ".json", ".yml", ".yaml")
EXCLUDE = re.compile(r"node_modules|[\\/]\.git[\\/]|[\\/]dist[\\/]|[\\/]build[\\/]|venv")
# Caracteres de control prohibidos en XML 1.0 (se conservan TAB, LF y CR).
BAD = re.compile("[\x00-\x08\x0b\x0c\x0e-\x1f]")

sanitized = skipped = 0

for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = [d for d in dirnames
                   if d not in (".git", "node_modules", "dist", "build", "venv")]
    for fn in filenames:
        if not fn.endswith(EXTS) or fn.endswith(".bak"):
            continue
        path = os.path.join(dirpath, fn)
        if EXCLUDE.search(path):
            continue

        with open(path, "rb") as fh:
            raw = fh.read()

        try:
            text = raw.decode("utf-8")
        except UnicodeDecodeError:
            print(f"  [OMITIDO] {fn} no es UTF-8 valido. Conviertelo a UTF-8 primero.")
            skipped += 1
            continue

        cleaned = BAD.sub("", text)
        if cleaned == text:
            continue

        if dry_run:
            print(f"  [CAMBIARIA] {fn}")
        else:
            if backup:
                shutil.copyfile(path, path + ".bak")
            with open(path, "wb") as fh:
                fh.write(cleaned.encode("utf-8"))
            print(f"  [SANITIZADO] {fn}")
        sanitized += 1

print("")
verb = "Archivos que cambiarian" if dry_run else "Archivos sanitizados"
print(f"Revision finalizada. {verb}: {sanitized}. Omitidos por encoding: {skipped}.")
PY
