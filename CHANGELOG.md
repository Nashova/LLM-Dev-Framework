# Changelog

Historial de cambios del framework en sí. Formato basado en
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versionado
[SemVer](https://semver.org/lang/es/).

El framework predica que todo proyecto mantenga un CHANGELOG
([`changelog-template.md`](docs/02_governance_templates/changelog-template.md)) — este archivo es el
framework aplicándose a sí mismo la misma regla.

## [No liberado]

### Cambiado — anonimización completa (el repo es público)

- Los tres casos de estudio se anonimizaron y renombraron: ya no contienen nombres de sistema,
  cliente, sector, stack con versiones exactas, nombres de contenedores, columnas de base de datos ni
  identificadores internos. Ahora son `examples/case-study-admin-console.md` (caso A),
  `case-study-multi-repo-ecosystem.md` (caso B) y `case-study-batch-engine.md` (caso C). Se conservó
  el mecanismo de cada incidente y la regla que nació de él, que es lo único reusable.
- Se barrieron ~30 referencias a los nombres originales en `docs/`, `scripts/`, `README.md`,
  `AGENT_GUIDE.md` y `.gitattributes`.
- `README.md`: reescrito. Agrega la sección "Cómo se consume este repo" (copiar / submódulo /
  referencia), la distinción entre rutas `docs/` del framework y `Docs/` del proyecto destino, la
  sección de Requisitos, y la de Alcance (qué patrones aplican solo a SPA).

### Agregado

- `LICENSE` (MIT). El repo era público y reusable sin licencia declarada.
- `scripts/sanitize-encoding.sh` — el gemelo Bash que la documentación prometía y no existía.
- `scripts/bootstrap-ai.*`: flags `-Force`/`--force` y `-DryRun`/`--dry-run`.
- `scripts/sanitize-encoding.ps1`: flags `-DryRun` y `-Backup`.
- `scripts/safety-check.sh`: flag `--quiet` (paridad con el `.ps1`) y validación de sintaxis de los
  `.sh` modificados.
- `scripts/_config.template.ps1`: variables `ADO_ORG`/`ADO_PROJECT`/`ADO_REPO`, que
  `git-provider-pr.ps1` exigía y solo estaban en la versión `.sh`.
- `docs/02_governance_templates/README.md`: declara la estructura canónica `Docs/01-04` del proyecto
  destino, que dos documentos ya citaban como si estuviera definida ahí.

### Corregido — seguridad

- `scripts/bootstrap-ai.ps1`/`.sh` **destruían** un `CLAUDE.md`, `.cursorrules`, `GEMINI.md`,
  `.windsurfrules` o `copilot-instructions.md` preexistente sin avisar ni respaldar. Ahora detectan si
  el archivo lo generaron ellos (por el encabezado autogenerado); si no, lo dejan intacto y avisan.
  Con `--force` lo respaldan como `<archivo>.bak` antes de reemplazarlo.
- `scripts/git-provider-pr.sh`: el token viajaba como argumento de `curl`, visible en `ps` para
  cualquier usuario del host. Ahora va por stdin vía `curl --config -`.
- `scripts/sanitize-encoding.ps1`: decodificaba como UTF-8 sin validar, así que un archivo en
  Latin-1/Windows-1252 quedaba permanentemente corrompido con caracteres `U+FFFD`. Ahora valida y
  omite cualquier archivo que no sea UTF-8 válido.

### Corregido — correctitud

- `scripts/git-provider-pr.sh`: una respuesta de error de la API de GitHub se interpretaba como "el PR
  ya existe" y `ship.sh` terminaba con éxito. Ahora valida el código HTTP y la forma del JSON.
- `scripts/git-provider-pr.sh`: con un remoto Bitbucket o no reconocido, la función devolvía 0 y
  `ship` reportaba éxito sin haber creado ningún PR. Ahora devuelve 1.
- `scripts/safety-check.sh`: parseaba `git status --porcelain` con `awk '{print $2}'`, que rompe con
  rutas con espacios y con renombrados. Ahora usa `git diff --name-only -z` + `ls-files -z`.
- `scripts/safety-check.sh`: la detección de CRLF dependía de `file(1)` y hacía `grep` sobre una salida
  que incluye el nombre del archivo (un archivo llamado `algo-CRLF.sh` daba falso positivo). Ahora
  busca el byte CR directamente.
- `scripts/safety-check.sh`: con `set -u` y arrays vacíos, la expansión abortaba el script en bash 3.2
  (el que trae macOS de fábrica).
- `scripts/ship.sh`: sin `_config.sh` moría con un error críptico de bash; ahora falla con el comando
  exacto para crearlo. El título del PR se extrae con `printf` en vez de `echo`, que interpretaba
  `-n`/`-e` y secuencias de backslash en el mensaje de commit.
- `scripts/_config.template.sh`: `get_project_secret` devolvía un traceback de Python cuando faltaba
  una clave; ahora nombra la clave y el archivo.
- Todos los `.sh` se commitearon con el bit de ejecución (`100755`). Estaban en `100644`, así que
  `ship.sh` fallaba en el primer paso en un clon nuevo.
- `.gitignore`: excluía `.local/` completo, por lo que el `secrets.template.json` que la documentación
  exige trackear nunca se podía commitear. Ahora excluye `.local/*` con excepción de la plantilla.
- `AGENT_GUIDE.md`: dos bloques de instrucciones (`REGLAS DE DESPLIEGUE` y `SCHEMA & MIGRATIONS`)
  estaban truncados a media frase y habían perdido su marcador `TODO`, así que el flujo documentado
  los salteaba. Reconstruidos.
- `AGENT_GUIDE.md`: citaba `collaboration-style.md §2` para la regla "el código manda sobre la doc";
  §2 trata de otro tema. Ahora apunta a `doc-freshness-strategy.md`.
- `AGENT_GUIDE.md`: los tres ítems de checklist exclusivos de SPA están marcados como tales, con
  instrucción de borrarlos si el proyecto no tiene frontend.
- `bootstrap-ai` generaba `.agents/AGENTS.md`, pero `AGENT_GUIDE.md` documentaba la convención como
  `AGENTS.md` en la raíz. Unificado en la raíz.
- `scripts/README.md`: afirmaba que `validate-knowledge-base` valida citas `archivo:línea`; solo verifica
  que el archivo exista. Corregido, y agregada la sección de Dependencias (`curl`, `python3`).
- `docs/01_bootstrap/new-project-checklist.md`: no mencionaba `bootstrap-ai`, `get-project-map` ni
  `validate-knowledge-base`, y `universal-multi-ai-setup.md` apuntaba a "el paso correspondiente" de ese
  checklist, que no existía. Agregados.
