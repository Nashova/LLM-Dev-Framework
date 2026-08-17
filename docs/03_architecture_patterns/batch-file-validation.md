# Patrón: validación de archivos por lotes (posición fija / CSV) con concurrencia

Cómo estructurar un motor que recibe archivos externos (formato fijo por posición de columna, o CSV),
los valida contra un catálogo de reglas, y los rutea según el resultado — de forma que agregar un tipo de
archivo nuevo no requiera tocar código, que una instancia no dañe el trabajo de otra corriendo en
paralelo, y que un archivo con problemas no tumbe el resto del lote.

## Cuándo aplica

Cualquier sistema que recibe archivos de un tercero (un cliente, un sistema externo, un proceso de
integración) con un formato de datos fijo — posiciones de columna exactas, o CSV con encabezados — que
hay que validar antes de aceptarlos, y donde los archivos llegan en lotes (una carpeta con N archivos por
corrida), potencialmente con más de una instancia del validador corriendo al mismo tiempo sobre la misma
carpeta.

## Catálogo de layout externalizado, nunca hardcodeado en el código de validación

La definición de qué campos tiene cada tipo de archivo (tamaño, tipo de dato, si es requerido, valores
permitidos) vive en un archivo de configuración (JSON u otro formato de datos), no en el código. Agregar
un tipo de archivo nuevo, o un campo nuevo a uno existente, es una edición de ese archivo — nunca un
cambio de código ni una recompilación. El código de validación es genérico: itera las definiciones del
catálogo para el tipo de archivo que está procesando, sea cual sea. La ganancia real no es solo
"menos código" — es que alguien sin conocimiento del código (soporte, operaciones) puede ajustar
validaciones sin depender de un despliegue.

**Regla práctica:** si agregar un tipo de archivo nuevo requiere tocar el código de validación (más allá
de, en el peor caso, agregar una función de validación genuinamente nueva que el catálogo no puede
expresar todavía), el catálogo no está bien diseñado — el 90%+ de los tipos nuevos deberían resolverse
solo editando datos.

## Lock optimista por renombrado — la única barrera anti-colisión, y es sagrada

Cuando más de una instancia del validador puede correr sobre la misma carpeta al mismo tiempo (multi-
proceso, multi-servidor, un cron que se solapa con una corrida manual), la forma más simple y robusta de
evitar que dos instancias procesen el mismo archivo es un **renombrado atómico** como lock: antes de leer
un archivo, renombrarlo a un sufijo distintivo (ej. `.processing`); si el renombrado falla porque otra
instancia ya lo tiene, se omite; si tiene éxito, se procesa, y al terminar se renombra al destino final o
se revierte al nombre original si algo falla en el movimiento final.

**Reglas no negociables de este mecanismo** (violarlas produce archivos duplicados, corruptos, o
notificaciones duplicadas — no son detalles menores):
- El lock debe cubrir **todo** camino que termine moviendo el archivo — incluyendo el camino de "este
  archivo no es válido, se descarta", no solo el camino de validación exitosa. Un archivo descartado sin
  pasar por el lock es exactamente la misma clase de colisión que uno validado sin lock.
- Nunca reemplazar el renombrado por otro mecanismo (un archivo de lock separado, una tabla de estado en
  base de datos) sin una revisión completa — el renombrado atómico del sistema de archivos es lo que hace
  que la operación de "tomar el lock" sea indivisible; un mecanismo de dos pasos (verificar-y-luego-marcar)
  reintroduce la misma condición de carrera que el renombrado atómico evita.
- La adquisición del lock necesita su propia política de reintento (no solo la liberación) — un bloqueo
  transitorio del sistema de archivos (un antivirus escaneando, latencia de red) no es lo mismo que una
  colisión real con otra instancia, y tratarlos igual (fallar inmediatamente en vez de reintentar) produce
  falsos "archivo bloqueado" que no lo estaban.

## Un archivo con problemas nunca detiene el lote completo

Cada archivo se procesa dentro de su propio `try/catch` — una excepción no controlada en un archivo se
registra y el lote sigue con el siguiente. La alternativa (una excepción que se propaga y detiene todo el
lote) convierte un problema de un archivo en una interrupción total del servicio para todos los demás
archivos y clientes de esa misma corrida.

## Modo tolerante/permisivo, opt-in y con dos límites que nunca se cruzan

Algunos consumidores del sistema (clientes, integraciones) pueden necesitar tolerancia a errores de
contenido que el validador estricto normalmente rechazaría — para no bloquear su operación mientras
corrigen en origen. Este modo debe ser:

- **Opt-in por cliente/consumidor**, nunca un cambio de comportamiento global — un flag de configuración
  explícito, con default estricto si no se configura nada.
- **Limitado a errores de contenido** (un campo vacío, un valor con formato inválido) — nunca a errores de
  identidad del archivo (nombre no reconocido, tipo de archivo no soportado). Un archivo con nombre
  incorrecto no es "contenido con errores que se puede tolerar" — es un archivo que no se sabe qué es, y
  tolerarlo sería aceptar cualquier cosa.
- **Nunca silencioso** — un archivo aceptado a pesar de tener errores debe seguir apareciendo en cualquier
  reporte/notificación de errores, marcado explícitamente como "aceptado con errores por configuración",
  no como si hubiera pasado validación limpia. La tolerancia es sobre el destino del archivo, nunca sobre
  la visibilidad de que tuvo problemas.

## Ejemplo real (caso C)

Un motor de validación de archivos estructurados (catálogos de posición fija y listados en
CSV) implementa los cuatro elementos de este patrón: el layout de cada tipo de archivo vive en un JSON
(`FileLayoutConfig.json`) con tamaño/tipo/requerido/valores-permitidos por campo, sin que agregar un tipo
nuevo toque el código de validación; el lock es un renombrado a `.processing` con política de reintento
propia tanto para adquirir como para liberar (un archivo descartado por nombre no reconocido pasó, en un
momento, por una ruta que no adquiría el lock — encontrado y corregido); cada archivo del lote se procesa
en su propio `try/catch` dentro de un `Parallel.ForEachAsync`; y un modo "Permisivo" opt-in por origen
entrega archivos con errores de contenido al destino igual, pero siempre los sigue reportando por correo
con una marca visual distinta — nunca aplica a archivos con nombre o tipo no reconocido, que siempre se
rechazan sin excepción.

## Checklist corto

- [ ] ¿El catálogo de tipos de archivo/campos es datos externalizados, no código?
- [ ] ¿El lock cubre TODOS los caminos que mueven un archivo, incluyendo el de descarte?
- [ ] ¿La adquisición del lock tiene su propia política de reintento, no solo la liberación?
- [ ] ¿Un archivo con excepción no controlada detiene solo ese archivo, nunca el lote completo?
- [ ] Si hay un modo tolerante: ¿es opt-in, limitado a errores de contenido, y nunca oculta el error del
      reporte?
