<p align="center">
  <img src="docs/assets/banner.png" alt="LLM Dev Framework — construye software con agentes de IA, sin repetir los mismos errores" width="100%">
</p>

<p align="center">
  <a href="https://github.com/Nashova/LLM-Dev-Framework/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Nashova/LLM-Dev-Framework/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="Licencia MIT" src="https://img.shields.io/badge/licencia-MIT-blue.svg"></a>
  <img alt="Scripts en PowerShell y Bash" src="https://img.shields.io/badge/scripts-PowerShell%20%2B%20Bash-5391FE.svg">
  <img alt="Compatible con Claude, Gemini, Cursor, Copilot, Windsurf y Codex" src="https://img.shields.io/badge/compatible%20con-Claude%20%C2%B7%20Gemini%20%C2%B7%20Cursor%20%C2%B7%20Copilot%20%C2%B7%20Windsurf-8A5A2B.svg">
</p>

<p align="center"><b>Español</b> · <a href="README.en.md">English</a></p>

# LLM Dev Framework

> **Un LLM que repite el mismo error no es un fallo del modelo — es evidencia de que el aprendizaje no quedó documentado donde la IA lo volvería a leer en el momento en que importaba.**

Framework universal y reusable para construir, auditar y mantener software **con** modelos de lenguaje (Claude, Gemini, Antigravity, Cursor, Copilot, Windsurf, ChatGPT o cualquier agente de IA) como colaboradores técnicos activos — eliminando el ciclo de prueba y error.

No es una librería ni un generador de código: es un conjunto de **documentos, plantillas, skills y scripts** que se copian a tu proyecto para que cualquier LLM que trabaje en él encuentre las reglas, el contexto y las herramientas donde va a volver a leerlas en el momento en que importa.

## Contenido

- [Qué incluye](#qué-incluye)
- [Inicio rápido](#inicio-rápido)
- [Skills: los protocolos que se disparan solos](#skills-los-protocolos-que-se-disparan-solos)
- [Patrones de arquitectura](#patrones-de-arquitectura)
- [¿Funciona con un modelo local o pequeño?](#funciona-con-un-modelo-local-o-pequeño)
- [De dónde sale esto](#de-dónde-sale-esto)
- [Cómo se consume este repo](#cómo-se-consume-este-repo)
- [Alcance, requisitos y calidad](#alcance-requisitos-y-calidad)
- [Contribuir](#contribuir) · [Licencia](#licencia)

## Qué incluye

| Componente | Qué es | Dónde |
|---|---|---|
| **Guía maestra** | Fuente única de verdad que leen todas las IAs: reglas, flujo de trabajo y definición de hecho. | [`AGENT_GUIDE.md`](AGENT_GUIDE.md) |
| **9 skills** | Protocolos que se activan solos cuando hacen falta (verificar antes de afirmar, puerta de cambios riesgosos, auditoría previa a publicar…). | [`skills/`](skills/README.md) |
| **23 patrones** | Patrones de arquitectura y de colaboración humano-IA, cada uno nacido de un incidente real. | [`docs/03_architecture_patterns/`](docs/03_architecture_patterns) |
| **11 plantillas** | Gobierno listo para copiar: base de conocimiento, arquitectura, seguridad de cambios, postmortem, SOP, requerimientos, plan de proyecto… | [`docs/02_governance_templates/`](docs/02_governance_templates/README.md) |
| **7 principios** | Filosofía de colaboración humano-IA, memoria persistente y frescura de la documentación. | [`docs/00_philosophy/`](docs/00_philosophy) |
| **8 scripts** | Operación automatizada, cada uno en **PowerShell y Bash**: mapa del proyecto, validador anti-drift, conector multi-IA, instalador de skills, safety-check, ship, cliente de PR y limpieza de codificación. | [`scripts/`](scripts/README.md) |
| **3 casos de estudio** | Sistemas reales, publicados **anonimizados**: de ahí salen los patrones. | [`examples/`](examples) |

<details>
<summary>Ver el árbol completo del repositorio</summary>

```
LLM-Dev-Framework/
├── AGENT_GUIDE.md                       → La guía maestra universal (Single Source of Truth para todas las IAs)
├── LICENSE / CHANGELOG.md               → MIT; historial de cambios del framework
├── skills/                              → 9 skills propias que auto-disparan los protocolos del framework
│   ├── README.md                        → Qué hace cada skill y cómo instalarlas
│   ├── CATALOG.md                       → Catálogo curado de skills externas, con licencia verificada
│   └── <nombre>/SKILL.md                → Una carpeta por skill (formato Agent Skills)
├── scripts/                             → Herramientas operativas automatizadas (PowerShell + Bash)
│   ├── README.md                        → Qué hace cada script, sus flags y sus dependencias
│   ├── _config.template.ps1 / .sh       → Plantilla de configuración por proyecto (cópiala como _config.*)
│   ├── get-project-map.ps1 / .sh        → Mapa mental instantáneo: ramas, dirty files, métricas y puertos
│   ├── validate-knowledge-base.ps1 /.sh → Validador de citas archivo:línea en docs (Anti-Drift)
│   ├── bootstrap-ai.ps1 / .sh           → Conector Multi-IA (genera CLAUDE.md, AGENTS.md, .cursorrules, etc.)
│   ├── install-skills.ps1 / .sh         → Traduce skills/ al formato nativo de 8 herramientas de IA
│   ├── sanitize-encoding.ps1 / .sh      → Limpieza de mojibake y caracteres de control XML
│   ├── safety-check.ps1 / .sh           → Verificación de sintaxis, line-endings y doc viva
│   ├── git-provider-pr.ps1 / .sh        → Crea PR/MR vía API REST (GitHub/GitLab/Azure DevOps/Bitbucket)
│   └── ship.ps1 / .sh                   → Pipeline de commit, test, deploy y PR
├── docs/
│   ├── 00_philosophy/                   → 7 principios de colaboración humano-IA, memoria y frescura
│   ├── 01_bootstrap/                    → Checklist de arranque + guía de instalación por herramienta de IA
│   ├── 02_governance_templates/         → 11 plantillas listas (Knowledge Base, SDD, Postmortem, SOP, REQ, PROY, CSV)
│   └── 03_architecture_patterns/        → 23 patrones arquitectónicos probados en producción
└── examples/                            → 3 casos de estudio anonimizados (casos A, B y C) + una auditoría del propio framework
```

</details>

## Inicio rápido

Todos los comandos se ejecutan **desde la raíz de tu proyecto**, no desde el repo del framework. `$FW` es la ruta donde lo clonaste.

```bash
git clone https://github.com/Nashova/LLM-Dev-Framework.git
FW="$PWD/LLM-Dev-Framework"

cd /ruta/a/tu-proyecto
cp "$FW/AGENT_GUIDE.md" .                                # 1. adapta las secciones <!-- TODO --> a tu proyecto
bash "$FW/scripts/bootstrap-ai.sh"                       #    genera CLAUDE.md, GEMINI.md, AGENTS.md, .cursorrules…
bash "$FW/scripts/install-skills.sh" --target . --tool claude   # 4. instala las skills (o cursor, copilot, windsurf…)
```

En Windows, cada script tiene su gemelo `.ps1`: `powershell -File $FW\scripts\bootstrap-ai.ps1`.

<details>
<summary><b>Guía completa en 5 pasos</b></summary>

1. **Bootstrap de Reglas e IAs**: copia `$FW/AGENT_GUIDE.md` a la raíz de tu proyecto, reemplaza las secciones marcadas `<!-- TODO -->` con la realidad de tu proyecto, y luego genera los archivos que cada herramienta de IA espera:

   ```bash
   bash "$FW/scripts/bootstrap-ai.sh"
   ```

   (En Windows: `powershell -File $FW\scripts\bootstrap-ai.ps1`.) Se corre con **tu proyecto** como directorio actual — genera `CLAUDE.md`, `.cursorrules`, `GEMINI.md`, etc. junto a tu `AGENT_GUIDE.md`, y pide confirmación antes de sobrescribir cualquier archivo que ya exista.
2. **Estructura Documental**: copia `$FW/docs/02_governance_templates/` a tu proyecto como `Docs/03_governance_and_guidelines/` y renombra cada plantilla quitándole el sufijo `-template` (ej. `architecture-template.md` → `architecture.md`). Empieza llenando `architecture.md` y `change-safety.md`.
3. **Scripts de Operación**: copia `$FW/scripts/` a tu proyecto, renombra `_config.template.ps1`/`.sh` como `_config.ps1`/`.sh` y ajusta las variables de tu stack. Ese archivo **sí se commitea** (no contiene secretos); los secretos van en un archivo aparte gitignored — ver [`secrets-management.md`](docs/03_architecture_patterns/secrets-management.md).
4. **Skills**: instala los protocolos que se auto-disparan, en el formato de la herramienta que uses:

   ```bash
   bash "$FW/scripts/install-skills.sh" --target . --tool claude
   ```

   Reemplaza `claude` por `cursor`, `copilot`, `windsurf`, `continue`, `gemini`, `codex` o `generic`; o usa `--tool all` si el equipo usa varias. Paso a paso por herramienta en [`docs/01_bootstrap/llm-setup-guide.md`](docs/01_bootstrap/llm-setup-guide.md).
5. **Verificación Continua**: ejecuta periódicamente `get-project-map` para dar contexto a la IA y `validate-knowledge-base` para asegurar que la documentación jamás mienta sobre el código.

El checklist detallado, con casillas, está en [`docs/01_bootstrap/new-project-checklist.md`](docs/01_bootstrap/new-project-checklist.md).

</details>

## Skills: los protocolos que se disparan solos

Una regla escrita en un documento de 400 líneas se lee la primera sesión y se olvida. Una **skill** con la descripción correcta se activa exactamente cuando hace falta. Se escriben una vez y un instalador las traduce al formato nativo de cada herramienta:

| Skill | Se dispara cuando… |
|---|---|
| [`verify-before-claiming`](skills/verify-before-claiming/SKILL.md) | vas a afirmar que algo existe, no existe o está en uso: verifica contra el estado real (ataca el error más caro de un LLM: afirmar algo falso con confianza). |
| [`safe-change-gate`](skills/safe-change-gate/SKILL.md) | vas a hacer un cambio riesgoso: migraciones, permisos, CI/CD, archivos protegidos o scripts contra un ambiente compartido. |
| [`project-onboarding`](skills/project-onboarding/SKILL.md) | empieza una sesión o cambia el contexto: obtiene el estado real del proyecto. |
| [`doc-drift-check`](skills/doc-drift-check/SKILL.md) | antes de un PR o release, o tras un refactor: detecta documentación que ya no dice la verdad. |
| [`incident-capture`](skills/incident-capture/SKILL.md) | ya se diagnosticó la causa raíz de un incidente real: lo registra en el catálogo para que no vuelva a pasar. |
| [`requirements-intake`](skills/requirements-intake/SKILL.md) | llega una petición de negocio sin especificar: la convierte en un requerimiento formal y rastreable. |
| [`ship-changes`](skills/ship-changes/SKILL.md) | se pide commitear, subir, desplegar o crear el PR: usa el pipeline del proyecto en vez de git a mano. |
| [`small-model-handoff`](skills/small-model-handoff/SKILL.md) | se trabaja con un modelo pequeño o local: prepara la tarea para que la ejecute de forma confiable. |
| [`pre-publication-audit`](skills/pre-publication-audit/SKILL.md) | un repo va a hacerse público o a entregarse a un tercero: audita secretos, datos de clientes e historial. |

```bash
bash scripts/install-skills.sh --list                                 # ver qué hay
bash scripts/install-skills.sh --target /mi-proyecto --tool claude     # o cursor, copilot, windsurf...
bash scripts/install-skills.sh --target /mi-proyecto --tool all        # si el equipo usa varias
```

Detalle completo en [`skills/README.md`](skills/README.md). Para skills de stack específico (React, .NET, Docker) ver [`skills/CATALOG.md`](skills/CATALOG.md), que apunta a los repos upstream con su licencia verificada en vez de redistribuirlos.

## Patrones de arquitectura

Cada patrón nació de un incidente real y declara su alcance en la primera línea.

| Área | Patrones |
|---|---|
| **Seguridad y control de cambios** | [`secrets-management`](docs/03_architecture_patterns/secrets-management.md) — secretos para scripts locales sin exponerlos en git · [`destructive-action-confirmation`](docs/03_architecture_patterns/destructive-action-confirmation.md) — confirmación para acciones irreversibles · [`rbac-cascade`](docs/03_architecture_patterns/rbac-cascade.md) — RBAC en cascada con fallback seguro · [`audit-logging`](docs/03_architecture_patterns/audit-logging.md) — quién hizo qué y cuándo · [`sandbox-mode-safety`](docs/03_architecture_patterns/sandbox-mode-safety.md) — un sandbox solo está probado si se probó contra un sistema real · [`incident-log-pattern`](docs/03_architecture_patterns/incident-log-pattern.md) — catálogo de incidentes reales |
| **Documentación y memoria para IAs** | [`ai-knowledge-base-verification`](docs/03_architecture_patterns/ai-knowledge-base-verification.md) — anti-drift con citas `archivo:línea` verificables · [`verify-external-assumptions`](docs/03_architecture_patterns/verify-external-assumptions.md) — un nombre heredado es una afirmación histórica, no un hecho · [`universal-multi-ai-setup`](docs/03_architecture_patterns/universal-multi-ai-setup.md) — configuración multi-IA desde una sola fuente · [`skills-and-triggers`](docs/03_architecture_patterns/skills-and-triggers.md) — protocolos auto-disparados · [`resumable-agent-workflows`](docs/03_architecture_patterns/resumable-agent-workflows.md) — procesos largos que sobreviven una interrupción · [`requirements-to-task-pipeline`](docs/03_architecture_patterns/requirements-to-task-pipeline.md) — de requerimientos a tareas y gestores · [`encoding-and-text-hygiene`](docs/03_architecture_patterns/encoding-and-text-hygiene.md) — higiene de codificación |
| **Datos, infraestructura y despliegue** | [`tolerant-migrations`](docs/03_architecture_patterns/tolerant-migrations.md) — migraciones para bases nuevas y legadas · [`branch-per-environment-config`](docs/03_architecture_patterns/branch-per-environment-config.md) — configuración por ambiente cuando se promueve por rama · [`proxy-dns-cache-invalidation`](docs/03_architecture_patterns/proxy-dns-cache-invalidation.md) — caché DNS del proxy tras reconstruir un contenedor · [`multi-repo-orchestrator`](docs/03_architecture_patterns/multi-repo-orchestrator.md) — repo raíz + N repos de código · [`orm-serialization-safety`](docs/03_architecture_patterns/orm-serialization-safety.md) — serialización segura con ORM · [`batch-file-validation`](docs/03_architecture_patterns/batch-file-validation.md) — validación de archivos por lotes con concurrencia |
| **Frontend** (solo si hay SPA) | [`zero-routing-frontend`](docs/03_architecture_patterns/zero-routing-frontend.md) — sin enrutador central que editar · [`strict-ui-layout-boundaries`](docs/03_architecture_patterns/strict-ui-layout-boundaries.md) — límites de layout sin scroll global · [`standardized-loading-framework`](docs/03_architecture_patterns/standardized-loading-framework.md) — estados de carga con skeletons · [`centralized-api-interceptors`](docs/03_architecture_patterns/centralized-api-interceptors.md) — instancia HTTP única con interceptores |

## ¿Funciona con un modelo local o pequeño?

Sí, y no bajando la calidad del entregable. El framework tiene tres tipos de componente y **solo uno se degrada con el tamaño del modelo**: los **scripts** son deterministas (un modelo de 7B corriendo `safety-check` obtiene el resultado idéntico a uno de frontera), las **plantillas** casi no se degradan, y el **juicio** sí se degrada mucho.

La estrategia es entonces mover trabajo desde el modelo hacia la estructura: un paso por turno con criterio de terminado verificable por comando, contexto mínimo dirigido, plantillas en vez de redacción libre, y verificación externa tras cada paso. La guía completa —con qué esperar de un 7B / 14B / 30B, la escalera de degradación y qué **no** delegarle nunca— está en [`docs/00_philosophy/working-with-small-models.md`](docs/00_philosophy/working-with-small-models.md).

Lo que recomendamos es el modelo híbrido: un modelo grande descompone y revisa, un modelo local ejecuta, y los scripts verifican. La skill `small-model-handoff` existe para producir ese plan en el formato correcto.

## De dónde sale esto

Nace de destilar la experiencia real en tres sistemas de escala, stack y problemática radicalmente distintas. Los tres casos se publican **anonimizados** — sin nombres de sistema, cliente, sector, infraestructura ni identificadores internos — porque lo único reusable es el mecanismo del incidente y la regla que nació de él.

1. **Caso A — consola administrativa interna** (backend Python + SPA sobre contenedores detrás de un proxy reverso). Originó los patrones de seguridad en despliegues, catálogo de incidentes, RBAC granular y scripts sin dependencia de CLIs externos. Ver [`examples/case-study-admin-console.md`](examples/case-study-admin-console.md).
2. **Caso B — ecosistema multi-repo en un sector regulado** (backend MVC + SPA + dos motores de reportes, media docena de repos independientes). Aportó la base de conocimiento verificable en dos niveles, la gestión de configuración por ambiente, el mapa mental instantáneo, la memoria persistente entre sesiones y el pipeline formal de requerimientos a tareas. Ver [`examples/case-study-multi-repo-ecosystem.md`](examples/case-study-multi-repo-ecosystem.md).
3. **Caso C — motor de validación y ruteo por lotes** (aplicación de consola sobre un runtime compilado, con concurrencia entre instancias). Aportó los patrones de aislamiento sandbox estricto, verificación de asunciones externas, validación por lotes con lock optimista y sincronización multi-agente. Ver [`examples/case-study-batch-engine.md`](examples/case-study-batch-engine.md).

Además, [`examples/case-study-self-audit.md`](examples/case-study-self-audit.md) documenta cómo el framework se auditó a sí mismo.

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

## Alcance, requisitos y calidad

**Alcance.** El framework se destiló de proyectos web y de consola, y algunos patrones son **condicionales al tipo de aplicación**. Los patrones de frontend (`zero-routing-frontend`, `strict-ui-layout-boundaries`, `standardized-loading-framework`, `centralized-api-interceptors`) aplican solo si tu proyecto tiene una SPA. Si tu proyecto es un CLI, un servicio backend, una librería o una app móvil, ignóralos — y borra los ítems correspondientes del checklist de tu `AGENT_GUIDE.md` en vez de dejarlos como reglas que no aplican. Cada patrón declara su alcance en su primera línea.

**Requisitos.**

- **PowerShell 5.1+** (Windows) o **Bash 4+** (Linux/macOS/WSL) — cada script existe en ambos sabores.
- **git** en el `PATH`.
- Para los scripts `.sh`: `curl` y `python3` (para parsear el JSON de las APIs de git sin depender de `jq`).
- Opcional: `gh` CLI. Si no está instalado, `git-provider-pr` usa la API REST directamente.

**Calidad.** El framework se aplica a sí mismo lo que predica: la [integración continua](.github/workflows/ci.yml) corre en cada cambio su propio `safety-check` y su validador anti-drift de citas `archivo:línea` (en Bash y en Windows PowerShell 5.1), exige que cada script tenga su gemelo `.ps1`/`.sh`, que los `.ps1` sean ASCII puro y que ningún enlace relativo de la documentación esté roto.

## Contribuir

Issues y pull requests son bienvenidos. Lo más valioso es un **patrón con evidencia**: un incidente real, la causa raíz y la regla que lo evita. Lee [`CONTRIBUTING.md`](CONTRIBUTING.md) antes de empezar; para vulnerabilidades, [`SECURITY.md`](SECURITY.md).

## Licencia

MIT — ver [`LICENSE`](LICENSE).
