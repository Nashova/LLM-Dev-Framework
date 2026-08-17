---
name: requirements-intake
description: Convertir una petición de negocio en un requerimiento o proyecto formal, rastreable. Úsala cuando el usuario o el cliente pida una funcionalidad nueva sin especificarla, cuando digan "el cliente quiere X", "necesitamos agregar Y", "levanta un requerimiento", o cuando una petición llegue por correo o chat y haya que registrarla antes de empezar a construir. NO la uses para bugs (esos van al catálogo de incidentes) ni para trabajo ya entregado (eso va al CHANGELOG).
---

# De una petición suelta a un requerimiento rastreable

El problema que resuelve: **trabajo pedido pero no entregado** se pierde entre el catálogo de incidentes
(que es solo para lo que ya se rompió) y el CHANGELOG (que es solo para lo ya entregado). Sin un registro
propio, la petición vive en la cabeza de alguien o en un hilo de correo, y reaparece como urgencia.

## Paso 0 — ¿Es un requerimiento?

| Es | No es |
|---|---|
| Funcionalidad nueva pedida por negocio | Un bug → `incident-capture` |
| Cambio de comportamiento que negocio decidió | Deuda técnica que vos detectaste |
| Algo pedido y aún no entregado | Algo ya entregado → CHANGELOG |

## Paso 1 — Elegir la forma

Dos tipos, según el tamaño:

- **`REQ-AAAA-NNN`** — cambio acotado, una sola entrega. Plantilla:
  `docs/02_governance_templates/requirement-spec-template.md`.
- **`PROY-AAAA-NNN`** — iniciativa multi-fase con desglose de tareas. Plantilla:
  `docs/02_governance_templates/project-plan-template.md`.

Si dudás: empezá como `REQ`. Promoverlo a `PROY` cuando se vea que no cabe en una entrega es más barato
que abrir un proyecto de tres fases para algo que eran dos días.

## Paso 2 — Pedir criterio, no adivinar

Esta es la parte donde un LLM pierde más valor. Una petición de negocio casi nunca llega completa, y las
preguntas faltantes **no tienen respuesta técnica correcta**. Adivinar se siente productivo y cuesta una
ronda entera de retrabajo.

Preguntá explícitamente, **con opciones concretas**, todo lo que caiga en estas categorías:

- **Alcance**: ¿aplica a todos los casos o solo a algunos? ¿A qué usuarios/roles?
- **Casos límite**: ¿qué pasa si el valor no cabe, si el registro no existe, si llega vacío?
- **Efectos observables**: ¿cambia algo que un sistema externo monitorea (códigos de salida, formato de
  archivo, un reporte)?
- **Visibilidad del error**: ¿un caso rechazado debe seguir apareciendo en el reporte, o se omite?

> Regla del framework: si la decisión es puramente técnica (qué índice, qué nombre de función), decidí y
> seguí. Si afecta lo que el usuario ve, el comportamiento en un caso límite, o el alcance de lo que se va
> a construir, **preguntala** — con opciones, no en abstracto.

## Paso 3 — Criterios de aceptación verificables

Escribilos en formato Gherkin (`Dado / Cuando / Entonces`). El criterio para saber si están bien: **otra
persona podría verificar si se cumplieron sin preguntarte nada**. Si un criterio dice "que funcione bien"
o "que sea rápido", todavía no es un criterio.

## Paso 4 — Estado y prioridad los define negocio

La priorización MoSCoW (`Must` / `Should` / `Could` / `Won't`) **la decide negocio, no vos**. Si nadie la
definió, el requerimiento queda sin priorizar y eso es información honesta — no le pongas `Should` por
defecto para que la tabla se vea completa.

## Paso 5 — Una sola fuente por dato

**No dupliques en el registro nada que ya viva en otro lado.** Si el detalle técnico está en el
`architecture.md`, linkealo; no lo copies. Un dato copiado en dos lugares se desincroniza, y después nadie
sabe cuál manda.

Si el equipo usa un gestor externo (ClickUp, Jira, Asana), exportá con
`docs/02_governance_templates/clickup-jira-task-export-template.csv`. El registro en el repo sigue siendo
la fuente de verdad de **la especificación**; el gestor externo lleva el estado de ejecución.

## Checklist

- [ ] Es trabajo pedido y no entregado (no un bug, no algo ya hecho).
- [ ] Tipo elegido: `REQ` acotado o `PROY` multi-fase.
- [ ] Toda pregunta de negocio se preguntó explícitamente con opciones concretas; nada adivinado.
- [ ] Criterios de aceptación verificables por un tercero.
- [ ] Prioridad definida por negocio, o marcada como no definida.
- [ ] Nada duplicado de otro registro.

## Relacionado

- `docs/02_governance_templates/requirements-tracking-template.md` — el registro completo y su máquina de estados.
- `docs/03_architecture_patterns/requirements-to-task-pipeline.md`
- `docs/02_governance_templates/discovery-questionnaire.md` — si el proyecto arranca de cero.
- `docs/00_philosophy/collaboration-style.md` §1 — pedir criterio, no adivinar.
