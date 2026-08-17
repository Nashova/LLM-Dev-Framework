# Checklist: aplicar este framework a un proyecto nuevo

Orden recomendado. No es necesario completar todo antes de escribir la primera línea de código real — varios pasos están marcados como "cuando corresponda", no "día 1".

## Antes de escribir código

- [ ] Correr el [cuestionario de discovery](../02_governance_templates/discovery-questionnaire.md) con el cliente/stakeholder. No adivinar respuestas — las preguntas sin responder son las que más caro salen de descubrir tarde.
- [ ] Decidir stack (backend, frontend, base de datos, infraestructura de despliegue) en base a las respuestas del discovery.
- [ ] Decidir qué herramienta(s) de IA va a usar el equipo (Claude Code, Cursor, Copilot, etc.) y qué proveedor de git (GitHub, GitLab, Azure DevOps, Bitbucket).
- [ ] Copiar [`AGENT_GUIDE.md`](../../AGENT_GUIDE.md) a la raíz del proyecto nuevo y rellenar las secciones `<!-- TODO -->` con lo decidido en los pasos anteriores. **Borrar los ítems del checklist que no apliquen a este tipo de proyecto** (los marcados *(Solo SPA)* si no hay frontend, por ejemplo) — un checklist con ítems irrelevantes se deja de leer completo.
- [ ] Correr `scripts/bootstrap-ai.ps1` (o `.sh`) desde la raíz del proyecto para generar los archivos que cada herramienta de IA espera (generado: `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md`) a partir de `AGENT_GUIDE.md`. Repetirlo cada vez que `AGENT_GUIDE.md` cambie — ver [`universal-multi-ai-setup.md`](../03_architecture_patterns/universal-multi-ai-setup.md). Si ya tenías un `CLAUDE.md` escrito a mano, el script **no** lo sobrescribe: avisa y lo deja intacto.
- [ ] Si el proyecto es (o va a ser) un repo raíz orquestando varias aplicaciones/servicios en repos Git independientes, en vez de un repo único — leer [`docs/03_architecture_patterns/multi-repo-orchestrator.md`](../03_architecture_patterns/multi-repo-orchestrator.md) antes de decidir la estructura de carpetas y declararlo explícitamente en `architecture.md`.
- [ ] Si los ambientes se promueven por rama de Git (no solo por variable de entorno) — leer [`docs/03_architecture_patterns/branch-per-environment-config.md`](../03_architecture_patterns/branch-per-environment-config.md) antes de diseñar el pipeline de CI/CD, y confirmar explícitamente si la configuración por ambiente es de runtime o se compila en el artefacto de build.
- [ ] Si el proyecto es (o va a ser) un motor de procesamiento de archivos por lotes (posición fija, CSV, o similar) — leer [`docs/03_architecture_patterns/batch-file-validation.md`](../03_architecture_patterns/batch-file-validation.md) antes de diseñar el catálogo de tipos de archivo y el mecanismo de lock entre instancias.
- [ ] Si el proyecto depende de un sistema externo que no controla (una base de datos ajena, una API de terceros) para datos que alimentan decisiones de ruteo/destino — leer [`docs/03_architecture_patterns/verify-external-assumptions.md`](../03_architecture_patterns/verify-external-assumptions.md) y planear cómo se va a verificar cada asunción heredada contra el sistema real, no solo confiar en la documentación existente.
- [ ] Si la herramienta de IA elegida soporta memoria persistente entre sesiones (o el equipo decide mantener un `MEMORY.md` a mano) — leer [`docs/00_philosophy/persistent-memory-pattern.md`](../00_philosophy/persistent-memory-pattern.md) y decidir la estructura de categorías desde el día 1, no improvisarla sesión a sesión.
- [ ] Si más de un desarrollador humano y/o más de un agente de IA van a trabajar sobre el mismo repositorio sin coordinarse en tiempo real entre sí — leer [`docs/00_philosophy/multi-agent-doc-sync.md`](../00_philosophy/multi-agent-doc-sync.md) y adoptar explícitamente la regla de que ninguna decisión de negocio/arquitectura cuenta como tomada si no está en un documento versionado.
- [ ] Crear (template) `Docs/03_governance_and_guidelines/architecture.md` a partir de [`architecture-template.md`](../02_governance_templates/architecture-template.md) — aunque sea solo con el stack y la estructura de carpetas planeada.
- [ ] Crear (template) `Docs/03_governance_and_guidelines/change-safety.md` a partir de [`change-safety-template.md`](../02_governance_templates/change-safety-template.md) — vacío, listo para la primera entrada real.
- [ ] Crear (template) `Docs/03_governance_and_guidelines/CHANGELOG.md` a partir de [`changelog-template.md`](../02_governance_templates/changelog-template.md).
- [ ] Copiar `scripts/_config.template.ps1` (o `.sh`) a (template) `scripts/_config.ps1`/`.sh` en el proyecto y llenar las variables — ver [`scripts/README.md`](../../scripts/README.md) del framework.
- [ ] Copiar `scripts/safety-check.*` y `scripts/ship.*` (y `git-provider-pr.*`) al proyecto tal cual — no deberían necesitar edición si `_config` está bien llenado.
- [ ] Crear `.gitignore` con, como mínimo, el directorio de secretos locales excluido (`.local/` o el nombre que se use) — ver [`secrets-management.md`](../03_architecture_patterns/secrets-management.md).
- [ ] Crear `.local/secrets.template.json` (SÍ trackeado, con valores de ejemplo) documentando qué claves va a necesitar cada persona que clone el repo y quiera correr los scripts.

## Durante el desarrollo del primer módulo/feature real

- [ ] Si el proyecto tiene control de acceso, diseñarlo siguiendo [`rbac-cascade.md`](../03_architecture_patterns/rbac-cascade.md) desde el primer módulo que lo necesite — no lo pospongas pensando "lo agrego después", retrofit de RBAC sobre código que ya asume acceso abierto es mucho más caro que diseñarlo desde el principio.
- [ ] Si hay una base de datos con migraciones, seguir [`tolerant-migrations.md`](../03_architecture_patterns/tolerant-migrations.md) desde la primera migración.
- [ ] Si el proyecto va a tener un modo sandbox/de pruebas que aísla side-effects reales (archivos, correos, llamados externos) — diseñarlo siguiendo [`sandbox-mode-safety.md`](../03_architecture_patterns/sandbox-mode-safety.md) desde el principio, y probarlo explícitamente contra un sistema real de solo lectura antes de confiar en que aísla de verdad, no solo contra datos ficticios.
- [ ] Antes de emprender cualquier tarea larga guiada por LLM de varios pasos (una auditoría, una migración de datos por etapas) que pueda cruzar un límite de sesión/contexto — leer [`resumable-agent-workflows.md`](../03_architecture_patterns/resumable-agent-workflows.md) y estructurarla con un archivo de progreso desde el primer paso, no después de la primera interrupción.
- [ ] El primer incidente real que rompa algo (va a pasar) documentarlo en `change-safety.md` de inmediato, con el formato de la plantilla — no esperar a "cuando haya varios para documentarlos juntos".
- [ ] Correr `ship.ps1`/`.sh` en vez de `git add`/`git commit`/`git push` manuales desde el primer commit — establecer el hábito temprano es mucho más fácil que migrar a él después de semanas de commits manuales.
- [ ] Correr `scripts/get-project-map.ps1`/`.sh` al inicio de cada sesión con el LLM (o al cambiar de contexto) — es la forma más barata de darle estado real del repo en vez de que lo intuya.
- [ ] Correr `scripts/validate-knowledge-base.ps1`/`.sh` antes de cada PR, en cuanto la documentación empiece a citar rutas de archivo concretas. Verifica que los archivos citados existan; no valida el número de línea.

## Cuando el primer despliegue a un ambiente compartido (staging/producción) esté cerca

- [ ] Escribir (template) `scripts/deploy.ps1`/`.sh` con la lógica específica de la infraestructura elegida (no está en este framework — es 100% específico de cada proyecto). `ship.ps1`/`.sh` lo va a invocar automáticamente si existe y se pasa `-Deploy`/`--deploy`.
- [ ] Escribir (template) `scripts/status.ps1`/`.sh` — un diagnóstico de una sola invocación que confirme si el ambiente está sano (contenedores/procesos corriendo, healthcheck responde, logs recientes sin errores). Ver `docs/00_philosophy/why-scripts-not-instructions.md` para por qué esto vale la pena como script y no como instrucción reconstruida cada vez.
- [ ] Si el ambiente de despliegue es un host **compartido con otros proyectos/equipos** (no dedicado), documentarlo explícitamente en `architecture.md` — es la causa más común y menos obvia de incidentes de infraestructura difíciles de diagnosticar (ver `examples/case-study-admin-console.md`).
- [ ] Confirmar que el flujo completo de `ship.ps1`/`.sh -Deploy` (o `--deploy`) funciona de punta a punta al menos una vez, con un cambio trivial, antes de confiar en él para cambios reales.

## Cuando el primer Pull Request real esté por crearse

- [ ] Confirmar que `ship.ps1`/`.sh` detecta el proveedor de git correctamente (ver `git-provider-pr.ps1`/`.sh`) y que el token/PAT necesario está en el archivo de secretos local.
- [ ] Copiar la plantilla de PR (template: `.github/PULL_REQUEST_TEMPLATE.md` para GitHub, `.azuredevops/pull_request_template.md` para Azure DevOps, o el equivalente del proveedor elegido) — ver `docs/02_governance_templates/` si hace falta adaptar el contenido.

## Cuando el proyecto tenga al menos una versión real desplegada

- [ ] Empezar `Docs/01_business_analysis/` con el primer proceso de negocio real documentado (no antes — un análisis de negocio escrito antes de que exista código real tiende a describir un sistema que nunca termina de construirse exactamente así).
- [ ] Empezar `Docs/04_product_roadmap/` con la primera auditoría real de deuda técnica.

## Cuando el proyecto crezca más allá de lo que `architecture.md` puede cubrir bien

- [ ] Si `architecture.md` empieza a tener secciones de cientos de líneas por dominio y encontrar algo específico requiere buscar en todo el archivo — leer [`docs/00_philosophy/two-tier-documentation.md`](../00_philosophy/two-tier-documentation.md) y considerar partir en una base de conocimiento operativa separada usando [`docs/02_governance_templates/ai-knowledge-base-template.md`](../02_governance_templates/ai-knowledge-base-template.md).
- [ ] Si el cliente/negocio empieza a pedir cambios con más frecuencia de la que se pueden mantener en la cabeza, y ni `change-safety.md` (incidentes) ni `CHANGELOG.md` (entregado) son el lugar correcto para registrarlos — dar de alta [`docs/02_governance_templates/requirements-tracking-template.md`](../02_governance_templates/requirements-tracking-template.md).
- [ ] Si algún checklist item de `AGENT_GUIDE.md` (o alguna entrada de `change-safety.md`) ya se olvidó/violó más de una vez a pesar de estar escrito, y la herramienta de IA del equipo soporta protocolos auto-disparados (skills, reglas por archivo, instrucciones por ruta) — considerar promoverlo, ver [`docs/03_architecture_patterns/skills-and-triggers.md`](../03_architecture_patterns/skills-and-triggers.md).

## Señal de que el framework está funcionando

Si después de unas semanas el equipo (humano o LLM) puede resolver "¿por qué pasa esto?" o "¿cómo hago X?" leyendo la documentación del proyecto en vez de teniendo que re-descubrirlo, el framework está cumpliendo su propósito. Si la documentación se siente como un ritual sin retorno, es señal de que se está llenando por llenar en vez de capturar conocimiento real — volver a `docs/00_philosophy/doc-freshness-strategy.md` y ajustar qué se documenta y cuándo.
