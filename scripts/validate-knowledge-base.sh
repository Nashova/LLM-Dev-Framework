#!/usr/bin/env bash
# validate-knowledge-base.sh - Validador universal de citas en la documentacion (Linux / macOS)

DOCS_PATH="${1:-docs}"
PROJECT_ROOT="${2:-.}"
ROOT_FULL="$(cd "$PROJECT_ROOT" && pwd)"
DOCS_FULL="$(cd "$ROOT_FULL/$DOCS_PATH" 2>/dev/null && pwd)"

if [ -z "$DOCS_FULL" ] || [ ! -d "$DOCS_FULL" ]; then
    echo "Error: No se encontro el directorio de documentacion en $ROOT_FULL/$DOCS_PATH"
    exit 1
fi

echo "--- Validando Citas de Codigo en Base de Conocimiento ---"
echo "Raiz del Proyecto: $ROOT_FULL"
echo "Directorio Docs  : $DOCS_FULL"
echo ""

checked=0
broken=0

while IFS= read -r doc; do
    while IFS= read -r line; do
        if echo "$line" | grep -qE '\(nuevo|\(propuesto|\(template|\(ejemplo|\(generado'; then
            continue
        fi
        
        # Extraer rutas entre backticks
        matches=$(echo "$line" | grep -oE '`[A-Za-z0-9_./\-]+\.[a-zA-Z0-9]+(:[0-9-]+)?`' | tr -d '`' | cut -d: -f1)
        for cite in $matches; do
            # Solo validar si contiene separador de ruta
            if [[ "$cite" == *"/"* ]] || [[ "$cite" == *"\\"* ]]; then
                ((checked++))
                found=0
                
                if [ -f "$ROOT_FULL/$cite" ] || [ -d "$ROOT_FULL/$cite" ]; then
                    found=1
                else
                    # Buscar en subdirectorios
                    for sub in "$ROOT_FULL"/*; do
                        if [ -f "$sub/$cite" ] || [ -f "$sub/src/$cite" ] || [ -f "$sub/app/$cite" ]; then
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
    done < "$doc"
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
