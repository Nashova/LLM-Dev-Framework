# Plantilla: control de proyectos y requerimientos

> Copiar a `Docs/03_governance_and_guidelines/requirements/` (o donde el proyecto prefiera, mientras quede junto a `change-safety.md`/`CHANGELOG.md`). Resuelve algo que ninguno de esos dos documentos cubre: llevar registro de **trabajo pedido pero todavía no entregado** — sin volverse un tercer lugar donde se duplican riesgos o decisiones que ya viven en otro lado.

## Por qué esto es un documento distinto de `change-safety.md` y `CHANGELOG.md`

- `change-safety.md` registra incidentes que **ya pasaron** — causa raíz de algo que se rompió.
- `CHANGELOG.md` registra cambios **ya entregados** — qué se liberó y cuándo.
- Este registro cubre lo que está **entre medio**: algo que el cliente/negocio pidió, que todavía no se entregó, y cuyo alcance/estado necesita quedar visible sin tener que reconstruirlo de una cadena de mensajes de chat o correo.

## Dos tipos de documento, con su propio ID

| Tipo | Cuándo usarlo | ID |
|---|---|---|
| **Requerimiento** | Un cambio puntual, acotado a una sola pantalla/flujo/módulo | `REQ-AAAA-NNN` |
| **Proyecto** | Una iniciativa multi-fase que probablemente agrupe varios Requerimientos hijos | `PROY-AAAA-NNN` |

Criterio rápido: si cabe en una sola pantalla y una sola fase de trabajo, es Requerimiento. Si toca varios módulos/repos o necesita más de una entrega, es Proyecto.

IDs secuenciales por año, **sin reutilizar números** aunque un documento se rechace o se pause — el siguiente número disponible de cada serie vive siempre en `Index.md` (ver abajo).

## Estado — máquina de estados simple

```
Borrador → En Revisión de Negocio → Aprobado para Diseño → En Diseño → En Desarrollo → En Prueba → Completado
                    ↓
                Rechazado                                          (o) Pausado, en cualquier punto
```

`Rechazado` deja constancia del motivo en el propio documento — no se borra el documento, así nadie vuelve a proponer lo mismo sin saber que ya se evaluó y por qué no se hizo. `Pausado` evita la pregunta recurrente de "¿qué pasó con aquello que se pidió hace meses?".

## Priorización — MoSCoW, la define negocio

Cuatro valores: `Must` (bloqueante), `Should` (importante, no bloqueante), `Could` (deseable si hay capacidad), `Won't (por ahora)` (reconocido y explícitamente fuera del ciclo actual). **La prioridad la asigna negocio, nunca quien captura el documento** — si todavía no se validó, el campo dice `Por priorizar`, nunca se inventa un valor para no dejarlo vacío. Esto evita el sesgo silencioso de que todo lo que el equipo técnico documenta termina pareciendo urgente porque nadie más lo calibró.

## `Index.md` — tabla maestra

Una sola tabla (o dos, una por tipo) con: ID, título, alcance/módulo, prioridad, estado, dependencias, origen, fecha, link al documento completo. Es la fuente rápida de verdad — el documento individual es la fuente completa. Actualizar la fila cada vez que cambie el estado de un documento; encabezar el archivo con "**Siguiente ID disponible**: `REQ-AAAA-NNN` · `PROY-AAAA-NNN`".

## La regla anti-duplicación (evita que este registro se vuelva un tercer lugar para lo mismo)

Este registro **no es** un catálogo de riesgos ni un log de decisiones — esos siguen siendo la única fuente de verdad:

| Si vas a anotar... | Va en... |
|---|---|
| Un riesgo técnico transversal (afecta a más de un requerimiento) | El registro de deuda técnica del proyecto |
| Una decisión técnica significativa ya tomada | El registro de decisiones de arquitectura del proyecto |
| Un supuesto o pregunta específico de UN solo requerimiento/proyecto | La sección "Preguntas abiertas" del propio documento — sí va aquí, es local |

Regla de bolsillo: si el riesgo o la decisión sobrevive al cierre de ESTE documento en particular (le importa a alguien que no está leyendo este documento en concreto), pertenece al registro transversal, no aquí.

## Plantilla mínima de un documento individual

```markdown
# [Requerimiento|Proyecto]: <título corto>

| Metadato | Valor |
|---|---|
| ID | REQ-AAAA-NNN / PROY-AAAA-NNN |
| Fecha | AAAA-MM-DD |
| Origen | <quién lo pidió, por qué canal> |
| Estado | Borrador |
| Prioridad (MoSCoW) | Por priorizar |
| Depende de / Bloquea | <otros IDs, o "Ninguno"> |

## Contexto y origen
## Comportamiento actual del sistema
<!-- con cita archivo:línea real -- ver ai-knowledge-base-template.md -->
## Alcance (incluye / explícitamente fuera de alcance)
## Preguntas abiertas
## Cierre (llenar solo al completarse)
- SDD/documentación técnica actualizada: <link o "N/A">
- Release/versión en que quedó: <link a CHANGELOG o "N/A">
- Decisión técnica generada (si aplica): <link al registro de decisiones o "N/A">
```

La sección "Cierre" es la que conecta este registro con el resto de la documentación sin duplicar contenido — un requerimiento completado debe apuntar a dónde quedó reflejado (el SDD actualizado, la entrada del CHANGELOG), no repetir esa información aquí.
