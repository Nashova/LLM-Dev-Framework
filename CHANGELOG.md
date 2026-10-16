# Changelog

Historial de cambios del framework en sí. Formato basado en
[Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versionado
[SemVer](https://semver.org/lang/es/).

El framework predica que todo proyecto mantenga un CHANGELOG
([`changelog-template.md`](docs/02_governance_templates/changelog-template.md)) — este archivo es el
framework aplicándose a sí mismo la misma regla.

## [No liberado]

### Agregado — presentación pública del repositorio y CI

El repositorio pasó a ser público; esta entrada lo deja presentable y le aplica a sí mismo lo que
predica (verificación automática en cada cambio).

- **Integración continua** ([`ci.yml`](.github/workflows/ci.yml)): en Linux corre `safety-check.sh`
  y `validate-knowledge-base.sh`, exige que cada script tenga su gemelo `.ps1` / `.sh` y verifica
  los enlaces; en Windows PowerShell 5.1 parsea todos los `.ps1`, exige que sean ASCII puro y corre
  `safety-check.ps1` y `validate-knowledge-base.ps1`.
- **Verificador de enlaces** ([`check-links.py`](.github/scripts/check-links.py)): detecta enlaces
  relativos y anclas `#sección` rotos en la documentación. Excluye a propósito las plantillas, cuyos
  enlaces apuntan a rutas del proyecto que las adopta.
- **README** rediseñado (banner, insignias, índice, tablas de skills y patrones, inicio rápido,
  secciones plegables) y su versión en inglés, [`README.en.md`](README.en.md).
- **Salud de la comunidad**: [`CONTRIBUTING.md`](CONTRIBUTING.md), [`SECURITY.md`](SECURITY.md)
  (reporte privado de vulnerabilidades), plantillas de issue y de pull request.

### Corregido — acentos en comentarios de tres `.ps1`

La regla del framework es que los `.ps1` se escriben en ASCII puro (PowerShell 5.1 lee un archivo sin
BOM como CP1252). Tres scripts —`get-project-map.ps1`, `validate-knowledge-base.ps1` y
`_config.template.ps1`— la incumplían con acentos en comentarios; inofensivos hoy, pero el chequeo de
la nueva CI los marcó, y la regla solo vale si se verifica. Se transliteraron (solo comentarios, sin
cambio de comportamiento ni de saltos de línea).

### Corregido — dos defectos encontrados al consumir el framework en un proyecto real

Nasheim es el primer proyecto que consume este framework de punta a punta, y esa corrida real
expuso dos defectos que no se ven usando el framework sobre sí mismo. Ambos se corrigieron aquí,
en el origen, en vez de parchearse en el proyecto destino.

- **`validate-knowledge-base.sh` daba falsos positivos hasta volverse inservible.** Sobre un
  proyecto real reportó 13 citas rotas de 27, todas falsas. Tres causas, tres correcciones:
  (1) resolvía toda cita como relativa a la raíz del proyecto, así que marcaba como rotos los
  enlaces relativos al documento que los cita — ahora resuelve ambas formas, igual que su gemelo
  `.ps1`, que ya lo hacía; (2) aceptaba cualquier extensión, así que contaba menciones en prosa de
  archivos de runtime (`.git/index.lock`) como citas de documentación — ahora usa la misma lista
  blanca de extensiones que el `.ps1`; (3) no tenía forma de expresar una cita legítima a otro
  repo — ver el punto siguiente. **Un validador que siempre falla se ignora, y entonces deja de
  detectar las roturas reales**, que es exactamente lo que este script existe para evitar.
- **`validate-knowledge-base.ps1` / `.sh`: nueva variable `KB_EXTERNAL_ROOTS`** en
  `_config.template.ps1` / `.sh`. Un proyecto que sigue este framework cita a propósito archivos
  que viven en el repo del framework ("ver `docs/03_architecture_patterns/xxx.md` del framework").
  Esas citas no están rotas, pero tampoco deberían ignorarse a ciegas: declarando el repo hermano,
  el validador las **verifica** de verdad contra el disco. Vacío por default — sin configurar, el
  comportamiento no cambia.
- **`validate-knowledge-base.sh`: de varios minutos a segundos.** Lanzaba dos subprocesos
  (`echo | grep`) por cada línea de cada documento; sobre 43 documentos son miles de forks, y en
  Git Bash para Windows la corrida pasaba de ~2 segundos a más de 8 minutos — inaceptable para algo
  que se supone corre antes de cada PR. Ahora filtra y extrae en una sola pasada por archivo:
  mismo resultado (mismo conteo, mismo orden, sin deduplicar), 9.9s contra 8+ minutos.
- **`bootstrap-ai.ps1` / `.sh`: los enlaces relativos de `.github/copilot-instructions.md` estaban
  rotos.** El script copiaba `AGENT_GUIDE.md` verbatim a un destino que vive un nivel más abajo, así
  que todos sus enlaces relativos (`README.md`, `docs/...`) apuntaban a un nivel que no existe desde
  `.github/`. Ahora reescribe los enlaces con el `../` que corresponde a la profundidad del destino.
  Se reescribe solo lo que es ruta relativa de verdad: quedan intactas las anclas (`#seccion`), las
  URLs, los `mailto:` y las rutas absolutas. Los cinco destinos de la raíz no cambian.

**Verificación** (no asumida): los dos validadores reportan ahora 34 citas revisadas / 0 rotas sobre
la documentación de este mismo repo, con conteos idénticos entre `.ps1` y `.sh`, y una prueba
negativa — agregar una cita a un archivo inexistente — hace fallar a ambos con salida 1. Para
`bootstrap-ai` se generó un proyecto de prueba con enlaces de cada tipo (relativo simple, con
carpeta, hacia arriba, con ancla, ancla pura, URL, `mailto:`, directorio) y se comparó la salida de
ambos formatos: idénticas, con `../` aplicado solo donde corresponde.

### Agregado — sistema de skills

- **`skills/`**: nueve skills propias del framework (MIT, sin dependencias de terceros) que codifican su
  filosofía en protocolos que se auto-disparan: `verify-before-claiming`, `project-onboarding`,
  `safe-change-gate`, `ship-changes`, `incident-capture`, `doc-drift-check`, `requirements-intake`,
  `pre-publication-audit` y `small-model-handoff`.
- **`scripts/install-skills.ps1` / `.sh`**: traduce cada skill —escrita una sola vez en formato Agent
  Skills— al formato nativo de ocho herramientas: Claude Code, Cursor, GitHub Copilot, Windsurf,
  Continue.dev, Gemini CLI, Codex/`AGENTS.md` y un playbook genérico con tabla de ruteo para cualquier
  modelo local. Soporta `--tool all`, `--skills`, `--dry-run`, `--force` y `--list`. Nunca sobrescribe un
  archivo que no generó él mismo.
- **`skills/CATALOG.md`**: catálogo curado de skills externas con su licencia **verificada contra el repo
  real**. Deliberadamente **no** se redistribuye contenido de terceros: varias skills que circulan no
  declaran licencia, y una del ecosistema de Anthropic está cubierta por términos comerciales, no OSS. El
  catálogo enlaza al upstream y explica cómo instalar desde la fuente.
- **`docs/01_bootstrap/llm-setup-guide.md`**: instalación paso a paso por herramienta, incluidos ChatGPT
  (como Project), Ollama, LM Studio y aider.
- **`docs/00_philosophy/working-with-small-models.md`**: cómo entregar con un modelo local de 7B-30B sin
  bajar la calidad. Define qué componente del framework se degrada con el tamaño del modelo (sólo el
  juicio; los scripts no se degradan en absoluto), una escalera de degradación de seis peldaños, qué
  esperar de cada tamaño, y la lista de tareas que no se delegan nunca.
- **`examples/case-study-self-audit.md`**: cuarto caso de estudio — el framework auditándose a sí mismo
  antes de publicarse. Documenta el método, los hallazgos por clase, los dos bugs que sólo aparecieron al
  ejecutar, y los dos errores del propio proceso de auditoría.

### Corregido — segunda ronda

- `scripts/get-project-map.ps1` hacía **siete recorridos recursivos completos** del disco (uno por
  lenguaje) y filtraba después con `Where-Object`, así que atravesaba `node_modules` siete veces y contaba
  dependencias ajenas como código propio. Ahora usa `git ls-files` como fuente primaria: instantáneo y ya
  respeta `.gitignore`. Fallback a recorrido de disco sólo si no es un repo git.
- `get-project-map` (ambos sabores) sólo reconocía Ruby, TypeScript, Python y C#. Ahora detecta además
  JavaScript, JSX, Vue, Svelte, Go, Java, Kotlin, PHP, Rust, Swift y SQL, y reporta el total de archivos
  considerados.
- `docs/03_architecture_patterns/encoding-and-text-hygiene.md`: documentado un modo de falla nuevo y no
  obvio — un guion largo dentro de un string de un `.ps1` **rompe el parseo entero del script** en
  PowerShell 5.1, porque lee el archivo sin BOM como CP1252 y el último byte del guion largo es `U+201D`,
  una comilla que PowerShell acepta como delimitador de cadena. Incluye el detector y la convención
  adoptada (los `.ps1` del framework se escriben en ASCII puro).
- `scripts/README.md`: documentada esa convención de encoding para los `.ps1`, con la explicación de por
  qué no es cosmética.

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
