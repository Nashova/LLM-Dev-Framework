# Patrón: higiene de codificación y compatibilidad XML/documental

Aplica a cualquier proyecto que opere en entornos mixtos (desarrollo en Windows, contenedores Linux, pipelines de CI/CD, motores de conversión a Word/PDF).

## El problema

En este tipo de entorno mixto son comunes dos fallas de codificación distintas:

1. **Mojibake**: caracteres acentuados corrompidos (`críticos` → `crÃ­ticos`, o similar) por abrir/guardar un archivo UTF-8 con un decodificador Windows-1252, o por re-guardarlo con doble codificación UTF-8.
2. **Caracteres de control prohibidos en XML**: bytes no imprimibles como `0x07` (BEL), `0x00` (NUL) o `0x0B` que se cuelan por copias de terminal o volcados binarios. Estos caracteres hacen que conversores de documentación (OpenXML, `python-docx`, algunos navegadores) fallen con errores del tipo "XML compatible: Unicode or ASCII, no NULL bytes or control characters".

## El patrón: UTF-8 sin BOM + sanitización automatizada

1. **UTF-8 sin BOM estricto**: todo archivo Markdown, YAML, JSON, script o código fuente se persiste en UTF-8 sin BOM.
2. **Sanitización automatizada de caracteres de control**: un script (`sanitize-encoding.ps1`/`.sh`, o integrado a `safety-check`) filtra cualquier carácter fuera del rango válido de XML 1.0:
   - Válidos: `0x9` (tab), `0xA` (LF), `0xD` (CR), `0x20`–`0xD7FF`, `0xE000`–`0xFFFD`.
   - Cualquier otro carácter de control (`0x00`–`0x08`, `0x0B`–`0x0C`, `0x0E`–`0x1F`) se elimina automáticamente, no se corrige a mano archivo por archivo.
3. **Los formatos binarios nunca son la fuente de verdad**: Markdown (`.md`) es siempre el original versionado; Word/PDF se generan como artefactos derivados en una carpeta de exportación ignorada por git o sincronizada aparte.

## Regla práctica

- No corregir mojibake o caracteres de control a mano, archivo por archivo — correr el script de sanitización y dejar que el rango válido de XML 1.0 sea la única fuente de verdad de qué se elimina.
- Nunca versionar el `.docx`/`.pdf` generado como si fuera la fuente — solo el `.md` que lo produjo.

## Checklist corto

- [ ] ¿Los archivos de texto del repo están en UTF-8 sin BOM?
- [ ] ¿`sanitize-encoding.ps1`/`.sh` corre antes de cualquier pipeline de conversión a Word/PDF?
- [ ] ¿El `.docx`/`.pdf` generado vive fuera del control de versiones (o en una carpeta claramente marcada como derivada)?
