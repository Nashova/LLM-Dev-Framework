# Patrón: protocolos auto-disparados en vez de párrafos que se pueden olvidar

`AGENT_GUIDE.md` funciona escribiendo una vez las reglas importantes y confiando en que el LLM las lea al principio de cada sesión. Eso alcanza para la mayoría de las reglas. No alcanza para el subconjunto de reglas donde "el LLM se olvidó de leer esta sección esta vez" tiene un costo real (dinero, cumplimiento regulatorio, datos irrecuperables) — ahí conviene un mecanismo que no dependa de la memoria ni de la disciplina de lectura de cada sesión.

## El problema

`AGENT_GUIDE.md` (o su equivalente) crece con el tiempo. Cuanto más crece, más fácil es que una sesión nueva lo lea completo una vez al principio y, 40 turnos después trabajando en algo que sí tocaba una regla específica de la sección 6, ya no la tenga "activa" en el contexto de la conversación. Esto no es un defecto del LLM en particular — es una consecuencia de que la atención sobre un documento largo leído una vez decae con la distancia (en turnos) desde que se leyó.

## El patrón: promover a trigger cuando la prosa no basta

Varias herramientas de asistencia de IA para desarrollo soportan un mecanismo de **protocolo auto-disparado**: un fragmento de instrucciones que se activa automáticamente según la forma de la tarea (una palabra clave en lo que pide el usuario, la ruta del archivo que se va a tocar), sin depender de que el LLM recuerde ir a buscarlo. El nombre exacto y el mecanismo varían por herramienta:

| Herramienta | Mecanismo |
|---|---|
| Claude Code | `skills` (`.claude/skills/`) — se invocan por descripción de disparo, el propio modelo decide cuándo cargarlas según lo que el usuario pidió |
| Cursor | reglas por archivo/glob (`.cursor/rules/*.mdc` con `globs:`) — se inyectan automáticamente cuando se toca un archivo que matchea el patrón |
| GitHub Copilot | instrucciones por ruta (`.github/instructions/*.instructions.md` con `applyTo:`) |
| Otras / futuras | cualquier mecanismo de "instrucciones condicionales" que la herramienta ofrezca — el patrón es genérico, el mecanismo no |

**Regla práctica para decidir qué promover:** un ítem del checklist de `AGENT_GUIDE.md` (o una entrada de `change-safety.md` que ya se repitió) es candidato a convertirse en un trigger cuando cumple **cualquiera** de estos:
- Toca un archivo/área donde un error no es solo "hay que corregirlo" sino que tiene consecuencia real fuera del código (cumplimiento regulatorio, dinero, datos de un tercero, un archivo que un sistema externo parsea por posición/formato exacto).
- Ya se olvidó/violó al menos una vez a pesar de estar escrito en `AGENT_GUIDE.md`.
- Requiere un protocolo de varios pasos (no una sola advertencia de una línea) que sería pesado repetir siempre completo en el documento de entrada, pero que sí vale la pena cargar completo exactamente cuando aplica.

## Ejemplo real (caso B)

Tres protocolos se convirtieron en skills en vez de quedar como secciones de `CLAUDE.md`:
- Uno que se auto-carga **siempre** al iniciar cualquier tarea de modificación — el equivalente a forzar la lectura de `AGENT_GUIDE.md` en vez de confiar en que ya se leyó al principio de la sesión.
- Uno que se dispara ante señales de "algo no funciona" — un flujo de diagnóstico estructurado, para no reinventar el procedimiento de troubleshooting cada vez.
- Uno que se dispara específicamente al tocar los archivos que generan el output que un sistema externo de cumplimiento regulatorio va a parsear por posición de columna exacta — el de mayor consecuencia real de los tres, y el que menos sentido tiene dejar a la memoria de que alguien "se acuerde" de leer la advertencia.

## Qué NO convertir en trigger

No todo merece este tratamiento — convertir cada regla del checklist en un trigger separado produce el mismo problema que query fatigue en cualquier sistema de alertas: si todo dispara un aviso, todos se vuelven ruido y se empiezan a ignorar. Reserva el mecanismo para el subconjunto de reglas de consecuencia real identificado arriba; el resto vive bien como prosa en `AGENT_GUIDE.md`/checklist normal.

## Addendum: vendorizar skills de terceros requiere verificar el árbol real, no un resumen

Un ángulo distinto del mismo problema — no cuándo promover un protocolo propio a skill, sino cómo
adoptar con seguridad skills que ya escribió otra persona/comunidad. Si el plan es copiar skills de un
repositorio público a `.claude/skills/` (o el equivalente de la herramienta usada), el resumen que
devuelve una búsqueda web sobre "qué skills tiene ese repositorio" no es una fuente confiable — puede
describir nombres o contenido que no coinciden con lo que realmente existe. *Ejemplo real
(caso C):* un resumen de búsqueda enumeraba nombres de skills específicos de un repositorio de
terceros; varios de esos nombres no existían tal cual en el árbol real del repositorio (verificado
después contra un listado real de archivos vía API). Vendorizar contra ese resumen habría copiado
contenido que no correspondía a nada real. **Regla práctica:** antes de copiar cualquier skill de
terceros, verificar su existencia y contenido contra el árbol real del repositorio origen (un listado de
archivos, no un resumen de búsqueda), y curar el subconjunto que aplica al stack real del proyecto en vez
de vendorizar todo el repositorio origen sin filtrar.

## Portabilidad

Esto es lo menos portable de todo el framework — cada herramienta de IA implementa su propio mecanismo, con su propia sintaxis, y algunas no tienen ninguno. Si el equipo cambia de herramienta o usa varias en paralelo, el CONTENIDO del protocolo (qué verificar, en qué orden, qué NUNCA hacer) se escribe una sola vez en un documento normal versionado (por ejemplo dentro de `Docs/03_governance_and_guidelines/`), y cada mecanismo de trigger de cada herramienta simplemente apunta/incluye ese contenido — así el contenido no se duplica ni se desincroniza entre triggers de distintas herramientas.
