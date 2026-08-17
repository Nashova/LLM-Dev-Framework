# Plantillas de Gobernanza y Procesos (Docs/)

Estructura estandarizada de plantillas listas para instanciar en cualquier proyecto nuevo, cubriendo desde la arquitectura y la seguridad operativa hasta el seguimiento de requerimientos y la resolución de incidentes.

## Estructura de destino en TU proyecto (convención canónica)

Estas plantillas viven en el framework bajo `docs/` (minúscula). Al instanciarlas en tu proyecto, la
convención que asume el resto del framework es **`Docs/`** (mayúscula inicial), con cuatro dominios
numerados:

```
Docs/
├── 01_business_analysis/          -- procesos de negocio reales, una vez que existe código real
├── 02_technical_architecture/     -- system overview, modelo de datos, endpoints
├── 03_governance_and_guidelines/  -- architecture.md, change-safety.md, CHANGELOG.md, guidelines de stack
└── 04_product_roadmap/            -- deuda técnica, requerimientos, roadmap
```

**Regla de llenado:** no hace falta crear los cuatro el mismo día. Cada dominio se empieza cuando hay
superficie real que describir — `03_governance_and_guidelines/` desde el día 1 (es el que un LLM lee
antes de tocar nada), `01_business_analysis/` y `04_product_roadmap/` solo cuando ya existe una versión
desplegada. El orden exacto está en
[`../01_bootstrap/new-project-checklist.md`](../01_bootstrap/new-project-checklist.md).

Si tu proyecto crece más allá de lo que `architecture.md` puede cubrir bien, el Nivel 2 (base de
conocimiento operativa para IAs) va en una carpeta **aparte** de esta estructura — ver
[`../00_philosophy/two-tier-documentation.md`](../00_philosophy/two-tier-documentation.md) y
[`ai-knowledge-base-template.md`](ai-knowledge-base-template.md).

## Catálogo de Plantillas

| Plantilla | Propósito | Audiencia |
|---|---|---|
| `ai-knowledge-base-template.md` | Estructura de Base de Conocimiento operativa para IAs dividida por dominio (Arquitectura, Datos, Endpoints, Flujos, Auth, Infra). | Asistentes de IA y Developers |
| `architecture-template.md` | Documento de diseño de sistema (SDD): stack, componentes, diagramas, archivos protegidos y dependencias ancladas. | Equipo Técnico |
| `change-safety-template.md` | Catálogo de incidentes reales y reglas de seguridad nacidas de cada fallo ("no repitas este error"). | Todos |
| `postmortem-log-template.md` | Bitácora de postmortems con 5 campos obligatorios: Fecha, Problema, Causa Raíz, Solución y Deuda/SOPs. | Operaciones y QA |
| `sop-template.md` | Procedimiento Operativo Estandarizado (SOP) con precondiciones, comandos paso a paso y plan de rollback. | Operaciones y DevOps |
| `requirement-spec-template.md` | Plantilla de captura de requerimiento de negocio (`REQ-YYYY-NNN`) con criterios de aceptación Gherkin. | Negocio y PM |
| `project-plan-template.md` | Especificación técnica de proyecto (`PROY-YYYY-NNN`) con desglose de tareas por fases. | Líder Técnico |
| `clickup-jira-task-export-template.csv` | Esquema CSV para exportar tareas autocontenidas a ClickUp, Jira o Asana en 1 clic. | PM / Agile |
| `discovery-questionnaire.md` | Cuestionario de descubrimiento para nuevos clientes o sistemas legados. | Consultoría / Tech Lead |
| `changelog-template.md` | Historial de versiones y entregables formal. | Clientes y Equipo |
| `requirements-tracking-template.md` | Control de requerimientos y proyectos pedidos pero no entregados, con IDs secuenciales, priorización MoSCoW y máquina de estados. | PM y Líder Técnico |
