# LLM Dev Framework

Un framework universal y reusable para construir, auditar y mantener software **con** modelos de lenguaje (Claude, Gemini, Antigravity, Cursor, Copilot, Windsurf, ChatGPT o cualquier agente de IA) como colaboradores técnicos activos — eliminando el ciclo de prueba y error.

No es una librería ni un generador de código: es un conjunto de **documentos, plantillas y scripts** que se copian a tu proyecto para que cualquier LLM que trabaje en él encuentre las reglas, el contexto y las herramientas donde va a volver a leerlas en el momento en que importa.

## Cómo se consume este repo

El framework **no se instala ni se agrega como dependencia**. Hay tres formas válidas de usarlo:

| Modo | Cómo | Cuándo conviene |
|---|---|---|
| **Copiar** (recomendado) | Clonas este repo aparte y copias `AGENT_GUIDE.md`, `scripts/` y `docs/02_governance_templates/` a tu proyecto. Tu copia evoluciona con tu proyecto. | Caso normal. Cada proyecto adapta las reglas a su realidad. |
| **Submódulo** | `git submodule add <url> .llm-framework` y referencias los patrones sin copiarlos. | Quieres recibir actualizaciones del framework sin re-copiar. |
| **Referencia** | No copias nada; lo consultas y escribes tus propias reglas inspiradas en los patrones. | Proyecto pequeño o exploratorio. |

> **Distinción clave al leer los documentos**: cuando un archivo dice `docs/03_architecture_patterns/xxx.md`
> **del framework**, se refiere a **este** repo. Cuando dice `Docs/03_governance_and_guidelines/xxx.md` (con
> mayúscula inicial), se refiere a un archivo que debe existir en **tu** proyecto y que tú creas a partir de
> las plantillas. La convención de carpetas del proyecto destino está fijada en
> [`docs/01_bootstrap/new-project-checklist.md`](docs/01_bootstrap/new-project-checklist.md).

## De dónde sale esto

Nace de destilar la experiencia real en tres sistemas de escala, stack y problemática radicalmente distintas. Los tres casos se publican **anonimizados** — sin nombres de sistema, cliente, sector, infraestructura ni identificadores internos — porque lo único reusable es el mecanismo del incidente y la regla que nació de él.

1. **Caso A — consola administrativa interna** (backend Python + SPA sobre contenedores detrás de un proxy reverso). Originó los patrones de seguridad en despliegues, catálogo de incidentes, RBAC granular y scripts sin dependencia de CLIs externos. Ver [`examples/case-study-admin-console.md`](examples/case-study-admin-console.md).
2. **Caso B — ecosistema multi-repo en un sector regulado** (backend MVC + SPA + dos motores de reportes, media docena de repos independientes). Aportó la base de conocimiento verificable en dos niveles, la gestión de configuración por ambiente, el mapa mental instantáneo, la memoria persistente entre sesiones y el pipeline formal de requerimientos a tareas. Ver [`examples/case-study-multi-repo-ecosystem.md`](examples/case-study-multi-repo-ecosystem.md).
3. **Caso C — motor de validación y ruteo por lotes** (aplicación de consola sobre un runtime compilado, con concurrencia entre instancias). Aportó los patrones de aislamiento sandbox estricto, verificación de asunciones externas, validación por lotes con lock optimista y sincronización multi-agente. Ver [`examples/case-study-batch-engine.md`](examples/case-study-batch-engine.md).

## Qué ofrece el Framework

```
LLM-Dev-Framework/
├── AGENT_GUIDE.md                       → La guía maestra universal (Single Source of Truth para todas las IAs)
├── LICENSE                              → MIT
├── scripts/                             → Herramientas operativas automatizadas (PowerShell + Bash)
│   ├── README.md                        → Qué hace cada script, sus flags y sus dependencias
│   ├── _config.template.ps1 / .sh       → Plantilla de configuración por proyecto (cópiala como _config.*)
│   ├── get-project-map.ps1 / .sh        → Mapa mental instantáneo: ramas, dirty files, métricas y puertos
│   ├── validate-knowledge-base.ps1 /.sh → Validador de citas archivo:línea en docs (Anti-Drift)
│   ├── bootstrap-ai.ps1 / .sh           → Conector Multi-IA (genera CLAUDE.md, AGENTS.md, .cursorrules, etc.)
│   ├── sanitize-encoding.ps1 / .sh      → Limpieza de mojibake y caracteres de control XML
│   ├── safety-check.ps1 / .sh           → Verificación de sintaxis, line-endings y doc viva
│   ├── git-provider-pr.ps1 / .sh        → Crea PR/MR vía API REST (GitHub/GitLab/Azure DevOps/Bitbucket)
│   └── ship.ps1 / .sh                   → Pipeline de commit, test, deploy y PR
├── docs/
│   ├── 00_philosophy/                   → 6 principios de colaboración humano-IA, memoria y frescura
│   ├── 01_bootstrap/                    → Guía paso a paso para arrancar cualquier proyecto nuevo
│   ├── 02_governance_templates/         → 11 plantillas listas (Knowledge Base, SDD, Postmortem, SOP, REQ, PROY, CSV)
│   └── 03_architecture_patterns/        → 23 patrones arquitectónicos probados en producción
└── examples/                            → 3 casos de estudio anonimizados (casos A, B y C)
```

## Cómo iniciar un proyecto nuevo en 4 pasos

Todos los comandos se ejecutan **desde la raíz de tu proyecto**, no desde el repo del framework. `$FW` es la ruta donde clonaste este repo.

1. **Bootstrap de Reglas e IAs**: copia `$FW/AGENT_GUIDE.md` a la raíz de tu proyecto, reemplaza las secciones marcadas `<!-- TODO -->` con la realidad de tu proyecto, y luego genera los archivos que cada herramienta de IA espera:

   ```bash
   bash "$FW/scripts/bootstrap-ai.sh"
   ```

   (En Windows: `powershell -File $FW\scripts\bootstrap-ai.ps1`.) Se corre con **tu proyecto** como directorio actual — genera `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, etc. junto a tu `AGENT_GUIDE.md`, y pide confirmación antes de sobrescribir cualquier archivo que ya exista.
2. **Estructura Documental**: copia `$FW/docs/02_governance_templates/` a tu proyecto como `Docs/03_governance_and_guidelines/` y renombra cada plantilla quitándole el sufijo `-template` (ej. `architecture-template.md` → `architecture.md`). Empieza llenando `architecture.md` y `change-safety.md`.
3. **Scripts de Operación**: copia `$FW/scripts/` a tu proyecto, renombra `_config.template.ps1`/`.sh` como `_config.ps1`/`.sh` y ajusta las variables de tu stack. Ese archivo **sí se commitea** (no contiene secretos); los secretos van en un archivo aparte gitignored — ver [`secrets-management.md`](docs/03_architecture_patterns/secrets-management.md).
4. **Verificación Continua**: ejecuta periódicamente `get-project-map.ps1` para dar contexto a la IA y `validate-knowledge-base.ps1` para asegurar que la documentación jamás mienta sobre el código.

El checklist detallado, con casillas, está en [`docs/01_bootstrap/new-project-checklist.md`](docs/01_bootstrap/new-project-checklist.md).

## Requisitos

- **PowerShell 5.1+** (Windows) o **Bash 4+** (Linux/macOS/WSL) — cada script existe en ambos sabores.
- **git** en el `PATH`.
- Para los scripts `.sh`: `curl` y `python3` (para parsear el JSON de las APIs de git sin depender de `jq`).
- Opcional: `gh` CLI. Si no está instalado, `git-provider-pr` usa la API REST directamente.

## Alcance: qué aplica a tu proyecto y qué no

El framework se destiló de proyectos web y de consola, y algunos patrones son **condicionales al tipo de aplicación**. Los patrones de frontend (`zero-routing-frontend`, `strict-ui-layout-boundaries`, `standardized-loading-framework`, `centralized-api-interceptors`) aplican solo si tu proyecto tiene una SPA. Si tu proyecto es un CLI, un servicio backend, una librería o una app móvil, ignóralos — y borra los ítems correspondientes del checklist de tu `AGENT_GUIDE.md` en vez de dejarlos como reglas que no aplican. Cada patrón declara su alcance en su primera línea.

## Principio Rector

> **Un LLM que repite el mismo error no es un fallo del modelo — es evidencia de que el aprendizaje no quedó documentado donde la IA lo volvería a leer en el momento en que importaba.**

## Licencia

MIT — ver [`LICENSE`](LICENSE).
