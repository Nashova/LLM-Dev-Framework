---
name: incident-capture
description: Registrar un incidente real en el catálogo de seguridad de cambios una vez que se encontró la causa raíz. Úsala cuando algo se rompió y ya se diagnosticó, cuando el usuario diga "se cayó", "dejó de funcionar", "esto ya nos había pasado", "documenta esto para que no vuelva a pasar", o cuando termines de arreglar un bug cuya causa no era obvia. NO la uses para bugs triviales ni para riesgos hipotéticos.
---

# Capturar un incidente donde se va a volver a leer

El principio rector del framework: **un LLM que repite el mismo error no es un fallo del modelo — es
evidencia de que el aprendizaje no quedó documentado donde la IA lo volvería a leer en el momento en que
importaba.**

Esta skill convierte un incidente resuelto en una entrada que evita la repetición.

## Qué SÍ entra y qué NO

**Entra** cuando se cumplen las tres:
1. Algo se rompió **de verdad** (no un hipotético, no un "esto podría pasar").
2. La causa raíz **no era obvia** desde el síntoma.
3. Alguien —humano o LLM— podría volver a caer en lo mismo.

**No entra**: un typo, un bug trivial con causa evidente, un riesgo que imaginaste. El catálogo crece
con incidentes reales; si se llena de hipotéticos, deja de leerse, y entonces no sirve para nada.

## Dónde va

`Docs/03_governance_and_guidelines/change-safety.md` — **no** en el CHANGELOG (ese es para lo entregado),
**no** en el registro de requerimientos (ese es para trabajo pedido y no entregado), **no** en un doc
nuevo de "notas de troubleshooting" que nadie va a saber buscar.

## Formato de la entrada

```markdown
## <N>. <Síntoma exacto, tal como se ve desde afuera>

- **Fecha:** AAAA-MM-DD
- **Síntoma:** el mensaje de error TEXTUAL, o el comportamiento observable. Este es el punto de
  entrada — alguien va a buscar por acá, así que va literal, no parafraseado.
- **Causa raíz:** qué lo causaba de verdad. Si el síntoma apuntaba a otro lado, decilo: esa
  desorientación es la parte valiosa.
- **Fix:** qué se cambió, con archivo:línea si aplica.
- **Regla que sale de esto:** una sola frase, en imperativo, accionable antes de actuar.
```

El campo que más se subestima es **Síntoma**. Escribí el error textual, con el stack trace si lo hay. La
próxima persona (o LLM) va a llegar buscando exactamente esa cadena; si la parafraseaste, no la encuentra.

## Después de escribir la entrada

1. **¿Ya se repitió una vez?** Entonces además de la entrada, agregá un ítem de una línea al checklist de
   `AGENT_GUIDE.md`. Un incidente que se repitió a pesar de estar documentado es señal de que el documento
   no se leía en el momento correcto — hay que moverlo a donde sí.
2. **¿Se repitió a pesar de estar en el checklist?** Entonces el mecanismo correcto ya no es prosa: es un
   chequeo automático (un ítem en `safety-check`, un trigger, un test). Ver
   `docs/03_architecture_patterns/skills-and-triggers.md`.
3. **Commiteá la entrada junto con el fix**, no en un commit aparte "de documentación" que se posterga y
   nunca llega.

## La escalera de mecanismos

Cada peldaño es más caro y más confiable. Subí solo cuando el anterior falló:

| Falló | Siguiente mecanismo |
|---|---|
| Nada aún (primer incidente) | Entrada en `change-safety.md` |
| Se repitió una vez | + ítem en el checklist de `AGENT_GUIDE.md` |
| Se repitió con el checklist puesto | + chequeo automático en `safety-check` o un trigger |
| Sigue pasando | + hacer el error imposible por diseño (tipos, permisos, un paso encapsulado en script) |

No arranques en el último peldaño: un mecanismo automático para un incidente que pasó una sola vez es
mantenimiento que nadie pidió.

## Checklist

- [ ] El incidente es real y su causa raíz no era obvia.
- [ ] El síntoma está textual, no parafraseado.
- [ ] La causa raíz explica por qué el síntoma engañaba.
- [ ] Hay una regla accionable de una frase.
- [ ] Va en `change-safety.md`, no en el CHANGELOG.
- [ ] Se commitea junto con el fix.
- [ ] Si ya se había repetido, subí un peldaño en la escalera.

## Relacionado

- `docs/03_architecture_patterns/incident-log-pattern.md` — el formato completo.
- `docs/02_governance_templates/change-safety-template.md`
- `docs/02_governance_templates/postmortem-log-template.md` — para incidentes que ameritan postmortem formal.
- `docs/00_philosophy/collaboration-style.md` §3, §4, §7.
