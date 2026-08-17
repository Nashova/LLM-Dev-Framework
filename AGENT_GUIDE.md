# [NOMBRE DEL PROYECTO] — Guía de entrada para el agente de IA

> Este archivo es la primera lectura obligatoria para cualquier sesión nueva con un LLM en este proyecto. Se versiona en el repo. Cópialo/symlinkéalo al nombre que tu herramienta espera:
>
> | Herramienta | Nombre de archivo |
> |---|---|
> | Claude Code | `CLAUDE.md` |
> | Cursor | `.cursorrules` o `.cursor/rules/main.mdc` |
> | GitHub Copilot | `.github/copilot-instructions.md` |
> | Gemini CLI / Code Assist | `GEMINI.md` |
> | Windsurf | `.windsurfrules` |
> | Convención emergente multi-herramienta | `AGENTS.md` |
>
> Si el proyecto usa más de una herramienta, mantén este archivo (`AGENT_GUIDE.md`) como la fuente única y symlinkea el resto a él en vez de mantener copias que se desincronizan. Si no puedes symlinkear (algunas herramientas exigen el archivo real, o Windows sin modo desarrollador no lo permite), corre `scripts/bootstrap-ai.ps1`/`.sh` — genera una copia literal marcada como autogenerada para cada herramienta y las resincroniza en un solo paso cada vez que edites este archivo, en vez de copiar y sincronizar a mano. Ver `docs/03_architecture_patterns/universal-multi-ai-setup.md` del framework LLM-Dev-Framework.

<!-- TODO: reemplaza todo lo que está entre corchetes. Borra este comentario cuando termines. -->

## ¿Qué es [NOMBRE DEL PROYECTO]?

<!-- TODO: 2-3 frases. Qué es, para quién, qué NO es. Un link a un doc de arquitectura más profundo si existe. -->

[Una frase describiendo el producto]. Detalle completo en [`README.md`](README.md) y [`Docs/02_technical_architecture/system_overview.md`](Docs/02_technical_architecture/system_overview.md).

> **Si algo en esta documentación contradice al código real, el código manda.** Repórtalo (una línea basta) en vez de asumir silenciosamente cuál de los dos está desactualizado — ver `docs/00_philosophy/doc-freshness-strategy.md` del framework LLM-Dev-Framework.

<!-- TODO: si el proyecto NO es un repo único sino un repo raíz orquestando varios repos independientes (uno por aplicación/servicio), decláralo aquí explícitamente y ver docs/03_architecture_patterns/multi-repo-orchestrator.md del framework -- cambia cómo hay que trabajar con worktrees y con qué rama verificar antes de afirmar que algo no existe. -->

## Reglas no negociables (rompen cosas si no se respetan)

Lectura obligatoria antes de tocar infraestructura, modelos de datos, o control de acceso:

1. **[`Docs/03_governance_and_guidelines/change-safety.md`](Docs/03_governance_and_guidelines/change-safety.md)** — catálogo de incidentes reales y las reglas que nacieron de cada uno. **No despliegues sin leerlo.** Empieza vacío (o casi) en un proyecto nuevo — crece con cada incidente real, nunca con hipotéticos. Ver `docs/03_architecture_patterns/incident-log-pattern.md` del framework LLM-Dev-Framework para el formato.
2. **[`Docs/03_governance_and_guidelines/architecture.md`](Docs/03_governance_and_guidelines/architecture.md)** — archivos protegidos (los que un LLM NUNCA debe modificar sin agregar líneas nuevas, solo extender), versiones ancladas de dependencias críticas, arquitectura completa del sistema.
3. **[`Docs/03_governance_and_guidelines/backend-guidelines.md`](Docs/03_governance_and_guidelines/backend-guidelines.md)** / **[`Docs/03_governance_and_guidelines/frontend-guidelines.md`](Docs/03_governance_and_guidelines/frontend-guidelines.md)** — convenciones de código específicas del stack elegido.
4. <!-- TODO: agrega aquí cualquier doc de referencia profunda equivalente a un "LLM_Onboarding.md" -- mapa de archivos, patrones prohibidos con ejemplos, FAQ operativo. Ver docs/00_philosophy/doc-freshness-strategy.md antes de escribirlo: este tipo de doc se desactualiza rápido si no se le pone un mecanismo de "parche puntual" desde el día uno. -->

> **Sobre la frescura de estas docs**: se van a desactualizar. Es inevitable — nadie recuerda tocar 4 documentos cada vez que cambia una línea de código. Lo que importa es tener un mecanismo que lo haga visible cuando pase (ver `docs/00_philosophy/doc-freshness-strategy.md`), no pretender que nunca va a pasar.

## Modelo de control de acceso / seguridad

<!-- TODO: si el proyecto tiene RBAC, roles, multi-tenancy, etc., resume el modelo aquí en 1 párrafo y linkea al detalle. Si el modelo cambia de fase en fase (en un caso real llevó 4 fases de rediseño sucesivas), documenta el ESTADO ACTUAL con la fecha del último cierre, no el historial completo -- el historial va en el CHANGELOG o en baselines fechados, no aquí. -->

Ver `docs/03_architecture_patterns/rbac-cascade.md` del framework LLM-Dev-Framework si vas a diseñar esto desde cero -- es un patrón probado (jerarquía de roles + cascada de alcance + funciones granulares con fallback seguro) que evita las trampas más comunes de RBAC mal diseñado.

## Cómo trabajar en este proyecto (flujo establecido)

<!-- Estos son los scripts core de CI/CD recomendados (ver docs/00_philosophy). La idea (comandos cortos y memorizables para operaciones repetitivas, en vez de que el LLM reconstruya el procedimiento cada vez desde cero) es el patrón -- ver docs/00_philosophy/why-scripts-not-instructions.md. -->

| Comando | Para qué |
|---|---|
| `./scripts/status.sh` | <!-- TODO: este script lo crea cada proyecto segun su infraestructura -- ver docs/01_bootstrap/new-project-checklist.md --> Diagnóstico del entorno (¿está todo corriendo? ¿healthchecks OK?). Cero tokens gastados en pedirle al LLM que lo intuya. |
| `./scripts/safety-check.sh` | Pre-commit: chequeos mecánicos rápidos (line endings, sintaxis, aviso de doc-viva desincronizada). Ver `scripts/safety-check.sh` del framework. |
| `./scripts/test.sh [--target ...]` | <!-- TODO: este script lo crea cada proyecto segun su stack de pruebas -- el framework no lo provee. Ver docs/01_bootstrap/new-project-checklist.md --> Suite de tests. |
| `./scripts/ship.sh -m "mensaje" [--deploy] [--no-pr]` | Flujo completo: safety-check → commit → (opcional) deploy → push → crea/actualiza PR. Ver `scripts/ship.sh` del framework -- detecta el proveedor de git (GitHub/GitLab/Azure DevOps/Bitbucket) y usa la API REST correspondiente, no asume un solo `gh`-style CLI. |

**Nunca edites código y hagas `git commit` a mano si el script de ship puede hacerlo** — el safety-check existe precisamente para atrapar el tipo de regresión que un humano o un LLM apurado no ve (line endings que rompen un container, sintaxis rota, documentación que quedó desincronizada).

## Reglas de despliegue por ambiente

<!-- TODO -- REGLAS DE DESPLIEGUE:
Si el proyecto corre detrás de un proxy reverso con contenedores, ver
`docs/03_architecture_patterns/proxy-dns-cache-invalidation.md` para evitar errores 502 al reconstruirlos.
Documenta aquí, por ambiente, si el push es directo o requiere aprobación humana explícita (Merge/Pull Request revisado, nunca merge directo). Es habitual que "staging" acepte push directo (ambiente compartido con el equipo, pero de bajo riesgo real) y que "producción"/el ambiente que ve el cliente final SIEMPRE exija un PR/MR aprobado a mano por una persona, incluso para cambios ya probados en staging -- una autorización de alcance no se extiende automáticamente a otro (ver docs/00_philosophy/collaboration-style.md §6). Si el proyecto además promueve por rama (development → staging → main) y NO solo por variable de entorno, lee docs/03_architecture_patterns/branch-per-environment-config.md antes de proponer cualquier optimización de pipeline que "compile/procese una sola vez y reuse en los N ambientes" -- es una trampa real, no hipotética. -->

## Convenciones de lenguaje y prosa

<!-- TODO: si el equipo/cliente tiene una convención de idioma/tono específica (español neutro vs regional, formalidad, términos técnicos que se mantienen en inglés, etc.), decláralo UNA vez aquí. La alternativa -- corregirlo cada sesión -- desperdicia turnos completos en algo que se resuelve con una frase. -->

## Schema de datos y migraciones

<!-- TODO -- SCHEMA & MIGRATIONS:
Si el proyecto usa un ORM con carga diferida, ver
`docs/03_architecture_patterns/orm-serialization-safety.md` para prevenir errores al serializar
objetos ya expirados tras un commit.
Si el proyecto usa un sistema de migraciones (Alembic, Prisma Migrate, Django migrations, Flyway,
Active Record, EF Core, etc.), documenta aquí: (a) que las migraciones son la ÚNICA fuente de verdad del schema -- nunca "sync automático" del ORM en producción, eso genera drift silencioso; (b) el patrón de migraciones tolerantes si el proyecto pasa por ambientes greenfield y legacy a la vez. Ver docs/03_architecture_patterns/tolerant-migrations.md del framework. -->

## Secretos y credenciales

<!-- TODO: declara dónde viven los secretos de ESTE proyecto (típicamente: variables de entorno + un archivo gitignored para desarrollo local/automatización de scripts) y qué NUNCA debe hardcodearse en un archivo trackeado. Ver docs/03_architecture_patterns/secrets-management.md del framework -- incluye el patrón exacto (archivo gitignored + función que lo lee en runtime) y el hallazgo real de por qué un secreto "temporal" hardcodeado en un script trackeado queda expuesto para siempre en el historial de git, incluso después de "corregirlo". -->

## Antes de tocar algo, revisa el checklist

<!-- TODO: esta es la sección de mayor retorno por línea escrita. Cada ítem aquí es una pregunta que, si el LLM se la hace ANTES de actuar, evita una clase entera de error. Empieza con estos genéricos y agrega los específicos del proyecto a medida que aparecen incidentes reales (cada incidente en change-safety.md que se repitió una vez es candidato a convertirse en un ítem de este checklist). -->

<!-- Los tres ítems siguientes aplican SOLO si el proyecto tiene un frontend SPA. Si es un CLI,
un servicio backend, una librería o una app móvil, BÓRRALOS de este checklist en vez de dejarlos
como reglas que no aplican -- un checklist con ítems irrelevantes se deja de leer completo. -->

- *(Solo SPA)* ¿Vas a crear una pantalla nueva? -> No modifiques el enrutador. Usa el patrón Zero-Routing registrando el módulo (`docs/03_architecture_patterns/zero-routing-frontend.md`).
- *(Solo SPA)* ¿Vas a manejar peticiones de API? -> No uses fetch manual, usa la instancia centralizada con interceptores (`docs/03_architecture_patterns/centralized-api-interceptors.md`).
- *(Solo SPA)* ¿La UI necesita scroll o estados de carga? -> Sigue las reglas estrictas de layout y skeleton (`docs/03_architecture_patterns/strict-ui-layout-boundaries.md` y `standardized-loading-framework.md`).
- ¿El archivo está marcado como PROTEGIDO en `architecture.md`? → solo agregar líneas, nunca modificar las existentes.
- ¿Toca el schema de datos? → migración formal, nunca un script ad-hoc ni "sync automático".
- ¿Toca un script shell? → verifica el line-ending correcto para el entorno donde va a correr (LF si corre en un container Linux, aunque se edite en Windows).
- ¿Toca control de acceso? → verifica que los roles/funciones existentes sigan funcionando para TODOS los roles, no solo el que estás probando.
- ¿Vas a agregar/cambiar una regla de negocio, una decisión operativa, o un archivo protegido? → actualiza la doc correspondiente en el MISMO commit. Si el pre-commit avisa que tocaste algo riesgoso sin tocar ninguna doc, no ignores el aviso sin pensarlo.
- ¿La acción es destructiva o difícil de revertir (borra datos, sobrescribe algo en producción, rota una credencial compartida)? → ver `docs/03_architecture_patterns/destructive-action-confirmation.md` del framework antes de construir el flujo. Como mínimo: quien lo ejecuta debe entender exactamente qué se va a perder y no debe poder disparar la acción por accidente.
- ¿Vas a ejecutar por primera vez un script/tarea que suena inocuo ("setup", "seed", "reset", "limpieza") contra un ambiente que no sea 100% local y descartable? → lee qué hace realmente antes de correrlo. El nombre no es garantía — un hallazgo real: una tarea llamada "test setup" resultó hacer `DROP DATABASE` contra una conexión que en dos de tres ambientes apuntaba a datos reales de un tercero, porque nunca se aprovisionó una base de test dedicada.
- ¿Vas a recomendar o construir sobre algo porque "está en el código, conectado y funcional"? → eso no es lo mismo que "está en uso operativo real". Verifícalo con el usuario antes de asumirlo — ver `docs/00_philosophy/collaboration-style.md` §8.
- ¿Alguien (tú mismo en un turno anterior, otro LLM, tu propia memoria persistente) propuso "hacer/compilar esto una sola vez y reusarlo en los N ambientes"? → si el proyecto promueve por rama y no solo por variable de entorno, confirma primero si la configuración por ambiente vive en runtime o compilada en el artefacto — ver `docs/03_architecture_patterns/branch-per-environment-config.md`.

## Si algo está roto y no sabes por dónde empezar

1. Corre `./scripts/status.sh` para ver el estado real (no asumas, verifica).
2. Si el problema es en un host **compartido con otros proyectos/equipos** (no dedicado a este proyecto), sospecha primero de un conflicto de recursos (puertos, memoria) con el vecino antes que de un bug propio — ver el incidente real documentado en `examples/case-study-admin-console.md` (colisión de puertos con un contenedor ajeno en el mismo host).
3. Revisa `Docs/03_governance_and_guidelines/change-safety.md` — es muy probable que si esto ya pasó antes, esté documentado ahí con la causa raíz y el fix exacto.

## Memoria entre sesiones

<!-- TODO: si la herramienta de IA usada soporta memoria persistente nativa entre sesiones (o el equipo mantiene un MEMORY.md a mano), decláralo aquí y ver docs/00_philosophy/persistent-memory-pattern.md del framework. Punto crítico a repetir siempre: una entrada de memoria es una fotografía de lo que era cierto cuando se escribió, no una garantía de lo que es cierto ahora -- antes de CONSTRUIR sobre algo recordado (no solo mencionarlo), verificar contra el estado real. -->

## Convenciones de comunicación

<!-- TODO: si quieres que el LLM formatee sus respuestas de cierta forma (links a archivos con línea exacta, resúmenes cortos al final de cada tarea, evitar narrar el proceso de pensamiento en voz alta, etc.), decláralo aquí una sola vez. -->
