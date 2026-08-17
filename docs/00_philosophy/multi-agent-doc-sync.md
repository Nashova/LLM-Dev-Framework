# Sincronizar documentación cuando hay más de un agente de IA (y más de un humano) editando el mismo repo

Complementa `two-tier-documentation.md` y `doc-freshness-strategy.md`, pero para un ángulo que ninguno de
los dos cubre directamente: qué pasa cuando no es una sola herramienta de IA usada sesión tras sesión por
la misma persona, sino **varios agentes de IA distintos (y varios humanos) editando el mismo repositorio,
sin coordinarse entre sí en tiempo real**.

## El problema que resuelve

`persistent-memory-pattern.md` resuelve la continuidad de una sesión a la siguiente para una misma
herramienta. Pero un proyecto real puede tener a más de un desarrollador humano, y más de un asistente de
IA (herramientas distintas, o la misma herramienta en sesiones que no comparten memoria entre sí)
tocando el código al mismo tiempo o en paralelo a lo largo del tiempo. Ninguno de ellos tiene, por
default, forma de saber qué decidió el otro. El riesgo no es solo "documentación desactualizada" (eso ya
lo cubre `doc-freshness-strategy.md`) — es **documentación contradictoria**: dos agentes, cada uno
razonable dentro de su propia sesión, llegando a decisiones incompatibles sobre la misma regla de negocio
porque ninguno sabía que el otro ya había decidido algo distinto.

## El patrón: la regla de negocio vive en un documento versionado antes de vivir en código, nunca al revés

**Regla práctica, en una sola frase:** ninguna regla de negocio, decisión de arquitectura, o expresión
regular/validación con impacto de negocio debe existir *solo* en código — tiene que existir primero (o en
el mismo cambio) en un documento Markdown versionado, y cualquier cambio de comportamiento debe actualizar
ese documento en el mismo commit que cambia el código.

Por qué esto resuelve el problema de sincronización sin necesitar que los agentes se coordinen en tiempo
real: un agente nuevo (de cualquier herramienta, en cualquier sesión) que necesita saber "¿cuál es la
regla aquí?" no depende de que el agente anterior le haya dejado un mensaje, ni de memoria compartida
entre herramientas distintas (que en general no existe) — depende solo de leer el documento versionado,
que por construcción está sincronizado con el código porque se actualizó en el mismo commit. La
sincronización pasa a ser una propiedad del repositorio (git), no del canal de comunicación entre agentes
(que no existe).

**Consecuencia práctica:** nunca asumir que una regla "obvia mirando el código" no necesita estar escrita
— si no está en el documento correspondiente, no cuenta como decisión tomada, sin importar cuánto tiempo
lleve el código funcionando así. Antes de reportar algo como un hallazgo nuevo, revisar primero si ya es
una decisión conocida y documentada (aceptada, pospuesta, o descartada explícitamente) — repetir un
hallazgo ya resuelto desperdicia el trabajo de quien ya lo resolvió antes.

## Qué hacer cuando dos agentes SÍ editan lo mismo casi al mismo tiempo

Este patrón no resuelve merge conflicts de git — los resuelve como cualquier conflicto normal de texto.
Lo que sí resuelve es el escenario más común y más silencioso: no un conflicto que git detecta, sino una
contradicción semántica que git no puede detectar porque las líneas no se solapan (dos secciones
distintas del mismo documento, o documentos distintos, afirmando cosas incompatibles). La única defensa
real contra eso es la misma regla de arriba llevada a rajatabla: si la regla está en el documento y no
solo en la cabeza de quien la escribió, la probabilidad de que el siguiente agente la contradiga sin
darse cuenta baja mucho, porque la va a leer antes de decidir algo en el mismo dominio.

## Relación con la auditoría/revisión de un proyecto con este patrón

Cuando se audita o revisa un proyecto que sigue esta regla, tratar las secciones de "pospuesto" o
"descartado" de sus documentos de gobernanza como decisiones ya tomadas por el equipo — no como hallazgos
pendientes de reportar de nuevo. Es la misma regla de `incident-log-pattern.md` (no re-descubrir lo ya
conocido) aplicada a decisiones de producto/arquitectura en vez de a incidentes.

## Ejemplo real (caso C)

Un proyecto con al menos dos desarrolladores humanos y más de un agente de IA (incluyendo una IA
identificada por nombre propio como autora de un reporte de auditoría anterior) trabajando sobre el mismo
repositorio adoptó explícitamente esta regla como principio rector, llamándola
"Markdown-as-Source-of-Truth": ninguna regla de negocio, arquitectura o expresión regular vive solo en
código, y cualquier cambio de comportamiento actualiza el `.md` correspondiente en el mismo commit. El
documento de gobernanza del proyecto lo declara en su primera línea de lectura obligatoria, y una
auditoría posterior (por un agente distinto al que escribió la regla) pudo re-verificar decisiones
tomadas meses antes — incluyendo cuáles seguían vigentes y cuáles ya se habían resuelto — leyendo
únicamente los documentos versionados, sin depender de memoria de ninguna sesión anterior ni de que
alguien le "pusiera al día" verbalmente.

## Qué NO resuelve este patrón

No reemplaza `persistent-memory-pattern.md` (preferencias del usuario, estado de conversaciones en curso
— eso sigue sin tener un buen lugar en documentos de código) ni `doc-freshness-strategy.md` (la
documentación igual puede quedar desactualizada si nadie sigue la disciplina). Resuelve específicamente la
sincronización de **reglas de negocio y decisiones de arquitectura** entre múltiples agentes que no
comparten memoria entre sí — no es una solución general de "mantené todo documentado siempre".
