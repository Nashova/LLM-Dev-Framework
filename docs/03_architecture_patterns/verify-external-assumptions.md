# Patrón: un nombre heredado (columna, campo, endpoint) es una afirmación histórica, no un hecho

Complementa `docs/00_philosophy/persistent-memory-pattern.md`, pero para un tipo de "memoria" distinto:
no lo que el LLM recuerda de sesiones anteriores, sino lo que el código o la documentación existente
*afirman* sobre un sistema externo (una base de datos, una API de terceros, un archivo de configuración
de otro equipo) que nadie volvió a verificar desde que se escribió.

## El problema

Cuando el código ya usa `columna_x` para leer un dato, o la documentación ya dice "el endpoint es
`/api/y`", la conclusión natural es tratarlo como un hecho verificado. Casi nunca lo es de forma
continua — es una afirmación que fue cierta (o que alguien asumió que era cierta) en el momento en que
se escribió, sobre un sistema que el proyecto no controla y que pudo cambiar, o que nunca se verificó
correctamente desde el principio. El riesgo es más alto exactamente cuando ese dato alimenta una decisión
de **ruteo o destino** (a qué carpeta se mueve algo, a qué servidor se conecta, a quién se le notifica) —
porque un valor vacío o incorrecto no siempre lanza un error visible; a veces solo produce un
comportamiento silenciosamente equivocado (una carpeta vacía en el log, un destino que resulta ser el
genérico por defecto).

## El patrón: verificar contra el sistema real antes de construir sobre la asunción

**Regla práctica**, en orden de exigencia creciente — el mismo principio de `persistent-memory-pattern.md`
aplicado a asunciones sobre sistemas externos en vez de a memoria de sesión:

- Si el dato ya se usa y **nunca produjo un síntoma raro**, no hace falta reverificarlo preventivamente —
  verificar todo constantemente sin motivo tiene su propio costo.
- Si el dato produce un síntoma que no tiene una explicación obvia en el código propio (un campo vacío que
  "no debería estar vacío", un comportamiento que solo pasa con algunos registros), la primera hipótesis a
  descartar es que la asunción sobre el sistema externo esté equivocada — antes de seguir buscando la
  causa en la lógica propia.
- Antes de **construir código nuevo** sobre un nombre de columna/campo/endpoint heredado que nadie
  reverificó recientemente, confirmarlo contra el sistema real (una consulta de solo lectura, un `describe`
  de esquema, un llamado de prueba a la API) — no asumir que porque el código ya lo usa, es correcto.
- Si no hay forma de verificarlo uno mismo (sin acceso, o el mecanismo de verificación disponible no es el
  adecuado para el caso), preguntarle directamente a quien sí tiene ese contexto — no adivinar variantes
  del nombre por prueba y error contra un sistema real ajeno.

## Señal de alerta específica

Un campo que se usa en exactamente un solo lugar de todo el código, sin ningún test que lo cubra, y sin
que nadie lo haya vuelto a mirar desde que se escribió, es la combinación de mayor riesgo: nada en el
código lo va a delatar si está mal, porque no hay una segunda referencia con la que pueda entrar en
conflicto ni un test que falle. Cuanto más aislado esté el uso de un dato heredado, menos se puede confiar
en que "si estuviera mal, ya se habría notado".

## Ejemplo real (caso C)

Un motor de procesamiento de archivos resolvía la carpeta destino de cada registro leyendo una columna
de ruta de una tabla de configuración — así documentado, así usado en el único lugar del código que la
consumía, sin ningún test. Al probar contra datos reales, la carpeta destino resultó vacía. La columna
correcta, confirmada directamente por quien conocía el esquema real, era otra completamente distinta que
nunca se había leído. La columna original no
estaba "casi bien" ni era una variante de nombre menor: era la columna equivocada, y lo fue probablemente
desde que el código se escribió — nadie lo notó antes porque nunca se había probado contra un registro
real con datos completos en esa columna específica. El fix fue puntual (una consulta, un modelo, un punto
de lectura) precisamente porque el dato solo se usaba en un lugar — pero encontrarlo dependió enteramente
de probar contra el sistema real, no de revisar el código con más cuidado.

## Checklist corto

- [ ] ¿Este nombre de columna/campo/endpoint se verificó contra el sistema real alguna vez, o se heredó
      de código/documentación sin reverificar?
- [ ] ¿Se usa en un solo lugar, sin test que lo cubra? (mayor riesgo de que un error pase inadvertido)
- [ ] ¿Alimenta una decisión de ruteo/destino, donde un valor vacío o incorrecto falla en silencio en vez
      de lanzar un error visible?
- [ ] Si hay una duda razonable, ¿se verificó contra el sistema real (o se preguntó a quien tiene ese
      contexto) antes de construir código nuevo sobre la asunción?
