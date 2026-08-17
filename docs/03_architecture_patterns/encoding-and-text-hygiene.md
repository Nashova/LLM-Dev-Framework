# Patrón: higiene de codificación y compatibilidad XML/documental

Aplica a cualquier proyecto que opere en entornos mixtos (desarrollo en Windows, contenedores Linux, pipelines de CI/CD, motores de conversión a Word/PDF).

## El problema

En este tipo de entorno mixto son comunes dos fallas de codificación distintas:

1. **Mojibake**: caracteres acentuados corrompidos (`críticos` → `crÃ­ticos`, o similar) por abrir/guardar un archivo UTF-8 con un decodificador Windows-1252, o por re-guardarlo con doble codificación UTF-8.
2. **Caracteres de control prohibidos en XML**: bytes no imprimibles como `0x07` (BEL), `0x00` (NUL) o `0x0B` que se cuelan por copias de terminal o volcados binarios. Estos caracteres hacen que conversores de documentación (OpenXML, `python-docx`, algunos navegadores) fallen con errores del tipo "XML compatible: Unicode or ASCII, no NULL bytes or control characters".
3. **Mojibake que rompe la ejecución, no sólo la lectura** — el caso menos obvio y el más caro de diagnosticar. Ver abajo.

## El caso que no parece de encoding: un guion largo que rompe un script

**Hallazgo real.** PowerShell 5.1 (el que viene de fábrica en Windows) lee un archivo `.ps1` **sin BOM**
como ANSI/CP1252, no como UTF-8. Y PowerShell acepta las comillas tipográficas (`U+2018`, `U+2019`,
`U+201C`, `U+201D`) como delimitadores de cadena válidos, igual que la comilla ASCII.

La combinación produce una falla desconcertante. Un guion largo `—` (`U+2014`, bytes UTF-8 `E2 80 94`)
decodificado como CP1252 se convierte en `â€"`, y ese último byte `0x94` **es** `U+201D`: una comilla de
cierre. Resultado: la cadena que contenía el guion termina antes de tiempo, y el parser produce una
cascada de errores (`Missing ')' in method call`, `Unexpected token`, `The '--' operator works only on
variables`) que apuntan a líneas que no tienen nada malo. El error real está en un carácter invisible a
simple vista, varias líneas más arriba.

Lo mismo aplica a `–`, `“`, `”`, `‘`, `’`: todos contienen bytes que en CP1252 caen en el rango
`0x91`–`0x94`, que son precisamente las comillas tipográficas.

**Dos formas de resolverlo**, no excluyentes:

- **Escribir los `.ps1` en ASCII puro** (`--` en vez de `—`, `a` en vez de `á`). Es la regla que aplica
  este framework a sus propios scripts: los `.ps1` no llevan acentos ni guiones largos. Los `.sh` y los
  `.md` no tienen la restricción.
- **Persistir los `.ps1` en UTF-8 con BOM.** El BOM hace que PowerShell 5.1 decodifique correctamente.
  Contradice la regla general de "UTF-8 sin BOM", así que si se elige este camino hay que declararlo como
  excepción explícita para `.ps1` en el `.gitattributes` y en la guía de estilo del proyecto.

Detectarlo es fácil una vez que se sabe qué buscar:

```powershell
# Marca cualquier .ps1 con caracteres que se vuelven comillas al decodificar como ANSI
$peligrosos = @([char]0x2014, [char]0x2013, [char]0x201C, [char]0x201D, [char]0x2018, [char]0x2019)
foreach ($f in (git ls-files -- '*.ps1')) {
    $t = [IO.File]::ReadAllText((Resolve-Path $f), [Text.Encoding]::UTF8)
    foreach ($c in $peligrosos) {
        if ($t.IndexOf($c) -ge 0) { Write-Host "$f contiene U+$('{0:X4}' -f [int]$c)" }
    }
}
```

La lección generalizable va más allá de PowerShell: **un problema de encoding puede presentarse como un
error de sintaxis**, y si se busca el bug en la lógica del programa no se encuentra nunca. Cuando un parser
se queja de un token que a simple vista está bien, revisar los bytes del archivo antes que la lógica.

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
- [ ] ¿Los `.ps1` están libres de guiones largos y comillas tipográficas (o persistidos con BOM, declarándolo como excepción)?
- [ ] ¿El script de sanitización **omite** los archivos que no son UTF-8 válido en vez de reescribirlos? Decodificar un archivo Latin-1 como UTF-8 y volver a guardarlo lo llena de `U+FFFD` y destruye los bytes originales de forma irreversible.
