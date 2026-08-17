# La documentación se va a desactualizar. Diséñala para eso.

## El problema

Cualquier documento de referencia profunda (un mapa de arquitectura, una guía de onboarding, un catálogo de convenciones) empieza preciso y se degrada con cada sesión que cambia código sin volver a abrirlo. Esto no es un fracaso de disciplina — es la consecuencia natural de que nadie recuerda actualizar 4 documentos cada vez que cambia una línea de código, ni un LLM ni una persona.

Hay dos formas malas de reaccionar a esto:
1. **Ignorarlo** — el documento queda "bonito" pero mintiendo, y alguien construye sobre una premisa falsa tarde o temprano.
2. **Reescribirlo entero cada vez que se toca** — carísimo en tiempo, y en la práctica nunca se hace lo suficientemente seguido como para que sirva.

## El patrón: parches puntuales fechados, no reescrituras completas

En vez de pretender que un documento largo se mantiene 100% preciso, acéptalo explícitamente y ponle un mecanismo de "parche puntual":

1. Al principio del documento, un aviso: *"Este documento se escribió/actualizó por última vez en [fecha]. No asumas que todo lo de abajo sigue vigente — ver la sección de parches para lo que sí se verificó recientemente."*
2. Cuando una sesión toca algo importante que el documento describe, en vez de reescribir todo el documento, agrega un párrafo fechado y acotado: *"Parche puntual del [fecha]: entre [fecha anterior] y esta fecha pasó X, Y, Z — NO reflejado en el resto de este documento. Este parche SOLO corrige [lo específico que toca], no reescribe todo."*
3. Los datos que cambian rápido y son fáciles de re-verificar (conteo de tests, número de la última migración, versión de una dependencia) se marcan explícitamente como "puede estar viejo, re-verificar con `[comando exacto]`" en vez de dar un número que va a mentir en dos semanas.

Esto es honesto sobre el costo real de mantener documentación viva, y le da a quien lee el documento (humano o LLM) la información que necesita para decidir cuánto confiar en cada parte: lo reciente, confiar; lo viejo, verificar antes de construir encima.

## El segundo mecanismo: el aviso automático en el pre-commit

No basta con el patrón de arriba si nada recuerda aplicarlo. El complemento es un chequeo mecánico (ver `scripts/safety-check.sh` del framework) que detecta cuándo un commit toca archivos de alto impacto (modelos de datos, lógica de control de acceso, servicios core, migraciones) sin tocar NINGUNA de las docs vivas del proyecto, y lo señala como **aviso, no bloqueo**.

Por qué aviso y no bloqueo: no todo cambio a esos archivos amerita una actualización de documentación (un fix de una línea no necesita un párrafo nuevo), y un bloqueo duro genera el reflejo de "tocar la doc con cualquier cosa para pasar el check" — que es peor que no tener el check. El aviso obliga a la pregunta consciente ("¿este cambio necesita documentarse?") sin forzar una respuesta automática.

**Mantén la lista de "docs vivas" que el chequeo reconoce actualizada.** Un hallazgo real: en un proyecto, el chequeo reconocía 5 documentos como "vivos" pero el equipo venía documentando activamente en 2 documentos MÁS que no estaban en esa lista — el aviso se disparaba en falso constantemente, entrenando a todos a ignorarlo. Un chequeo que genera falsos positivos con frecuencia se vuelve ruido, y el ruido se ignora — igual de peligroso que no tener el chequeo.

## Qué SÍ escribir de una sola vez y no volver a tocar

No todo documento necesita este tratamiento. Las reglas verdaderamente estables (convenciones de nombres, principios de arquitectura que no van a cambiar, la lista de archivos protegidos) se escriben una vez y se actualizan solo cuando la regla misma cambia — no tienen fecha de vencimiento porque no describen un estado del sistema, describen una decisión permanente. La distinción importa: mezclar "esto es una decisión fija" con "esto describe el estado actual, que cambia" en el mismo documento sin separarlos es la receta para que todo el documento se sienta poco confiable cuando solo una parte lo es.
