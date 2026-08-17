# Patrón: procesos largos de LLM que sobreviven una interrupción sin perder ni repetir trabajo

Cómo estructurar una tarea de varios pasos (una auditoría completa, una migración de datos por etapas,
cualquier trabajo que un LLM pueda tardar en terminar más de lo que dura una sesión/ventana de contexto)
para que una interrupción a mitad de camino — corte de sesión, límite de contexto, error de red — nunca
signifique volver a empezar ni adivinar qué ya se hizo.

## El problema

Una tarea larga guiada por un LLM normalmente lleva su progreso en la conversación misma: "ya revisé los
archivos A, B y C, ahora sigo con D". Eso funciona mientras la sesión no se interrumpe. En cuanto se
interrumpe — y en una tarea lo bastante larga, tarde o temprano pasa — retomarla depende de la memoria de
la sesión (que puede resumirse, perderse, o simplemente no estar disponible en una sesión nueva). El
resultado típico es uno de dos errores: repetir trabajo ya hecho (caro, y en el peor caso destructivo si
alguno de los pasos no es idempotente), o asumir que algo se completó cuando en realidad se interrumpió a
mitad de camino (peor, porque el hueco es invisible hasta que alguien lo nota mucho después).

## El patrón: un archivo de progreso es la única fuente de verdad, nunca la conversación

**Regla práctica:**

1. Antes de empezar, crear un archivo de progreso (ej. `PROGRESS.md`) que liste cada unidad de trabajo
   de la tarea completa, con un estado explícito (`PENDING` / `IN_PROGRESS` / `DONE`) — no una lista en la
   respuesta del LLM, un archivo real en disco.
2. Al empezar una unidad, marcarla `IN_PROGRESS` **antes** de hacer el trabajo — no después. Si la sesión
   se corta a mitad de la unidad, esa marca es la señal de que quedó a medias, no de que está completa.
3. Al terminar una unidad, dos cosas en el mismo momento (no en batch al final de todas las unidades):
   persistir su resultado en su propio archivo, y actualizar su fila en `PROGRESS.md` a `DONE`. Si el
   resultado se acumula solo en memoria para volcarlo todo al final, una interrupción antes de ese volcado
   final pierde TODO el trabajo ya hecho, no solo la unidad en curso.
4. Para retomar una tarea interrumpida: leer `PROGRESS.md`, tomar la primera fila que no diga `DONE`. Una
   fila en `IN_PROGRESS` al momento de retomar significa que se interrumpió a mitad de esa unidad
   específica — no asumir que el archivo de resultado correspondiente está completo; revisarlo o rehacer
   la unidad completa.
5. Las unidades ya en `DONE` no se re-ejecutan al retomar — son, por diseño, idempotentes: volver a
   correrlas debería producir el mismo resultado, así que no aportan información nueva salvo que algo
   debajo haya cambiado desde que se completaron (en ese caso, marcar la fila como obsoleta/`STALE`
   explícitamente en vez de asumir que sigue vigente, y re-ejecutar solo esas).

## Por qué esto es distinto de un log o un historial de commits

Un log registra lo que pasó, en orden, para consulta humana después del hecho. `PROGRESS.md` es
prescriptivo, no descriptivo — su función no es contar qué se hizo, es decirle a quien retome la tarea
(el mismo LLM en una sesión nueva, un LLM distinto, o un humano) exactamente qué hacer a continuación, sin
tener que leer ni interpretar el historial completo primero.

## Ejemplo real (caso C)

Una auditoría de código completa (revisar cada módulo contra su documentación y contra buenas prácticas
de la industria) se estructuró como 12 unidades de trabajo independientes, cada una con su propio archivo
de hallazgos bajo `docs/audit/findings/` (ejemplo), y un `docs/audit/PROGRESS.md` (ejemplo) con una tabla de estado por unidad.
Diez de las doce unidades se repartieron entre varios agentes en paralelo; cada uno escribió su resultado
en su propio archivo apenas terminó, y la fila correspondiente se marcó `DONE` inmediatamente — no se
esperó a que las diez terminaran para recién entonces escribir todo. El archivo de progreso incluye
explícitamente su propia instrucción de "cómo retomar" (leer la tabla, buscar la primera fila sin `DONE`)
como parte del documento mismo, no como una convención que hay que recordar por fuera de él.

## Checklist corto

- [ ] ¿Existe un archivo de progreso real en disco, no solo un plan mencionado en la conversación?
- [ ] ¿Cada unidad se marca `IN_PROGRESS` antes de empezar, no solo `DONE` al terminar?
- [ ] ¿El resultado de cada unidad se persiste en su propio archivo apenas se completa esa unidad, sin
      esperar a que terminen las demás?
- [ ] ¿El propio archivo de progreso explica cómo retomar si alguien lo abre sin contexto previo de la
      conversación original?
