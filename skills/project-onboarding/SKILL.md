---
name: project-onboarding
description: Obtener el estado real del proyecto al empezar una sesión, al cambiar de contexto, o cuando no sabes qué es este repositorio. Úsala antes de responder "¿qué es este proyecto?", antes de tu primera edición en una sesión nueva, y cuando el usuario diga "arranquemos", "ponte en contexto", "¿en qué estábamos?" o pida algo que dependa de qué rama/ambiente está activo.
---

# Ponerse en contexto sin gastar turnos adivinando

Una sesión nueva empieza sin saber nada del estado real: qué rama está activa, qué quedó sin commitear,
qué se decidió la semana pasada, qué archivos no se pueden tocar. Reconstruir eso preguntando o
explorando a ciegas gasta turnos y produce respuestas equivocadas con confianza.

**El orden importa**: primero el estado mecánico (barato, exacto), después las reglas (caro de leer, pero
es lo que evita romper cosas).

## Paso 1 — Estado mecánico del repo (siempre primero)

```bash
bash scripts/get-project-map.sh          # o: powershell -File scripts/get-project-map.ps1
```

Devuelve, en una sola invocación: ramas activas de cada repo (incluidos los anidados), archivos sin
commitear, últimos commits, métricas por stack y puertos de Docker Compose.

Léelo de verdad. Tres cosas que cambian tu plan y suelen pasarse por alto:

- **Hay trabajo sin commitear.** No empieces a editar los mismos archivos sin preguntar qué es eso.
- **La rama activa no es la que esperabas.** Ver `verify-before-claiming` antes de afirmar que algo
  no existe.
- **Hay repos anidados.** Cada uno tiene su propia rama y su propio estado. No asumas "un repo, un `.git`".

## Paso 2 — Las reglas no negociables

En este orden, y solo lo que aplique:

1. **`AGENT_GUIDE.md`** (o `CLAUDE.md`/`GEMINI.md`/`.cursorrules`, que son copias generadas del mismo
   archivo) — la guía de entrada. Trae el checklist previo a cualquier cambio.
2. **`Docs/03_governance_and_guidelines/change-safety.md`** — catálogo de incidentes reales. Si lo que
   vas a tocar ya rompió algo antes, la causa raíz y el fix exacto están ahí. **Leerlo antes de
   desplegar no es opcional.**
3. **`Docs/03_governance_and_guidelines/architecture.md`** — archivos PROTEGIDOS (los que solo se
   extienden, nunca se modifican), versiones ancladas y por qué.

Si alguno no existe todavía, dilo y sigue; no lo inventes.

## Paso 3 — Declarar qué entendiste

Antes de tocar código, resume en 3-5 líneas: qué es el proyecto, en qué rama estás, qué hay pendiente,
y qué restricción del checklist aplica a la tarea pedida. Es la forma más barata de que el usuario
detecte un malentendido **antes** de que se convierta en trabajo tirado.

## Si la documentación contradice al código

**El código manda.** Reportalo en una línea en vez de asumir en silencio cuál de los dos está
desactualizado — esa asimetría es información valiosa para el equipo, y callarla es cómo la
documentación empieza a mentir sin que nadie lo note.

## Checklist

- [ ] Corrí el script de mapa y **leí** la salida (no solo la ejecuté).
- [ ] Sé en qué rama estoy y si hay trabajo sin commitear.
- [ ] Leí el catálogo de incidentes si voy a tocar infraestructura, datos o control de acceso.
- [ ] Sé qué archivos están marcados como protegidos.
- [ ] Resumí mi entendimiento antes de editar.

## Relacionado

- `docs/00_philosophy/why-scripts-not-instructions.md` — por qué esto es un script y no un párrafo.
- `docs/00_philosophy/two-tier-documentation.md` — qué doc es para navegar y qué doc es entregable.
- `skills/verify-before-claiming/SKILL.md`
