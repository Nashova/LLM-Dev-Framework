# Caso C: motor de validación y ruteo de archivos por lotes

> Caso de estudio **anonimizado**. Los tres casos de `examples/` provienen de sistemas reales, pero se
> publican sin nombres de sistema, cliente, sector, infraestructura ni identificadores internos. Lo que se
> conserva es el mecanismo del incidente y la regla que nació de él — que es lo único reusable. Ver
> [`README.md`](../README.md) para el criterio de anonimización.

Tercer caso que retroalimenta este framework. **No confundir con el
[caso B](case-study-multi-repo-ecosystem.md)** — aunque ambos vienen de organizaciones con cumplimiento
regulatorio, este es un sistema completamente separado: un motor de consola sobre un runtime compilado, un
solo repositorio, sin frontend, sin RBAC, sin multi-repo. Su trabajo es validar y rutear masivamente archivos
estructurados (formatos de posición fija y CSV) antes de que lleguen a sistemas de destino. La diferencia de
forma es otra vez la razón por la que aporta patrones nuevos: ni el caso A ni el caso B tenían nada parecido
a procesamiento de archivos por lotes, concurrencia entre instancias del mismo proceso, o gobernanza de
documentación con más de un agente de IA editando el mismo repo.

## La forma del proyecto

Una aplicación de consola única, sin servidor web, invocada por un orquestador externo (cron) una vez por
carpeta de origen. Procesa hasta miles de archivos por corrida, con paralelismo configurable, y puede correr
como varias instancias simultáneas contra distintas carpetas — o, en el peor caso, accidentalmente contra la
misma. El catálogo de tipos de archivo soportados (qué campos tiene cada uno, qué formato, cuáles son
obligatorios) vive en un JSON versionado, no en código. La documentación de negocio y de arquitectura vive en
el mismo repositorio que el código, con una regla explícita de que ninguna decisión de negocio cuenta como
tomada si no está escrita ahí.

## Incidentes reales que dieron forma a las reglas nuevas

- **El modo sandbox protegía un side-effect y dejaba fugar otros dos.** Al ejecutar deliberadamente contra
  una base de datos productiva en modo solo lectura (para simular una carga real) en vez de contra datos
  ficticios, aparecieron dos fugas que ninguna prueba anterior había expuesto: la carpeta destino de los
  archivos válidos se resolvía a una ruta de red productiva en vez de a una carpeta local, y el correo de
  resumen estaba a punto de enviarse a destinatarios productivos en vez de al buzón de pruebas — porque la
  condición para usar el buzón de pruebas evaluaba "¿se encontró un registro real?" en vez de "¿está activo
  el modo sandbox?". Ninguna de las dos fugas se habría encontrado sin probar contra un sistema real. Ver
  [`sandbox-mode-safety.md`](../docs/03_architecture_patterns/sandbox-mode-safety.md), que nace directamente
  de este hallazgo. **La regla clave**: cada side-effect debe consultar la bandera de sandbox directamente, no
  una condición correlacionada con ella.
- **Una columna de base de datos, usada en un solo lugar de todo el código, resultó ser la equivocada.** La
  carpeta destino de cada registro se leía de una columna que nadie había vuelto a verificar contra el
  esquema real desde que se escribió el código. Al probar contra datos reales, la carpeta vino vacía — la
  columna correcta era otra completamente distinta, confirmada preguntando directamente a quien conocía el
  esquema. No había ningún test ni segunda referencia en el código que pudiera haber delatado el error antes.
  Ver
  [`verify-external-assumptions.md`](../docs/03_architecture_patterns/verify-external-assumptions.md).
- **Un intento de verificación directa contra la base de datos fue bloqueado por el propio entorno de IA.**
  Al no encontrar un registro por su nombre comercial (el query real filtra por un identificador interno
  exacto, no por nombre), el primer instinto fue correr una consulta SQL de diagnóstico directa para explorar
  la tabla — el clasificador de seguridad de la herramienta de IA bloqueó esa acción por salirse del flujo
  normal de la aplicación. La respuesta correcta no fue buscar un rodeo técnico para ejecutarla igual — fue
  explicarle al usuario exactamente qué se había intentado y por qué, y dejar que la persona decidiera cómo
  seguir (terminó siendo el usuario mismo quien confirmó el identificador correcto). **Un límite que la
  herramienta impone deliberadamente se respeta, no se evade.**
- **Una auditoría de código completa necesitaba sobrevivir cualquier interrupción sin perder ni repetir
  trabajo.** Se construyó un sistema de doce unidades de auditoría independientes, cada una con su propio
  archivo de hallazgos y una fila de estado en un archivo de progreso central, actualizada a `IN_PROGRESS`
  antes de empezar cada unidad y a `DONE` inmediatamente después — nunca en batch al final. Varias unidades
  corrieron en paralelo en agentes distintos sin perder esta propiedad. Ver
  [`resumable-agent-workflows.md`](../docs/03_architecture_patterns/resumable-agent-workflows.md), que
  documenta el patrón completo.
- **El motor de validación por lotes en sí es un patrón reconocible, no solo código de un proyecto.**
  Catálogo de layout en JSON, lock optimista por renombrado como única barrera anti-colisión entre instancias
  (con una brecha real encontrada y corregida: la ruta de archivos descartados por nombre no reconocido no
  pasaba por el lock, a diferencia de la ruta de archivos validados), y un modo tolerante opt-in que nunca
  oculta un error del reporte ni se aplica a archivos con nombre o tipo incorrecto. Ver
  [`batch-file-validation.md`](../docs/03_architecture_patterns/batch-file-validation.md).
- **Pedir criterio de negocio en vez de adivinar, varias veces en la misma feature.** Al diseñar una bandera
  de "modo permisivo", ninguna de las siguientes preguntas tenía una respuesta técnica correcta: ¿aplica a
  todos los tipos de archivo o solo a algunos?, ¿un archivo permisivo con errores debe seguir apareciendo en
  el correo de reporte?, ¿debe cambiar el código de salida del proceso (que un sistema externo monitorea)?,
  ¿un valor de CSV demasiado largo para su campo destino se trunca o se rechaza? Las cuatro se preguntaron
  explícitamente, con opciones concretas, en vez de elegir la que "sonaba razonable" — confirma la regla 1 de
  [`collaboration-style.md`](../docs/00_philosophy/collaboration-style.md) con un ejemplo distinto al del
  caso A.
- **Vendorizar skills de un repositorio de terceros verificando el árbol real, no el resumen de una búsqueda
  web.** El resumen inicial de una búsqueda describía nombres de skills que no coincidían con los que
  realmente existían en el repositorio origen — verificar contra el árbol de archivos real (una API de
  listado, no una búsqueda de texto) evitó vendorizar contenido inventado. Confirma
  [`skills-and-triggers.md`](../docs/03_architecture_patterns/skills-and-triggers.md) desde un ángulo
  distinto: no solo cuándo promover un protocolo propio a skill, sino cómo verificar contenido de terceros
  antes de adoptarlo.

## Cómo maduró la documentación (y por qué la gobernanza tuvo que cubrir más de un agente)

El proyecto ya tenía, antes de esta serie de sesiones, una regla de gobernanza explícita:
**Markdown-as-Source-of-Truth** — ninguna regla de negocio, arquitectura o expresión regular vive solo en
código, tiene que existir primero (o en el mismo cambio) en un documento versionado. La razón declarada para
esa regla no era estética: el repositorio tiene más de un desarrollador humano y más de un agente de IA
trabajando sobre el mismo código sin coordinarse en tiempo real entre sí. Sin esa regla, cada agente nuevo
tendría que redescubrir (o, peor, re-decidir de forma distinta) las mismas reglas de negocio que un agente
anterior ya había resuelto. Ver
[`multi-agent-doc-sync.md`](../docs/00_philosophy/multi-agent-doc-sync.md), que generaliza esta regla más
allá de este proyecto — es el ángulo de sincronización que ni
[`two-tier-documentation.md`](../docs/00_philosophy/two-tier-documentation.md) ni
[`doc-freshness-strategy.md`](../docs/00_philosophy/doc-freshness-strategy.md) cubrían todavía, porque ambos
asumen una sola herramienta de IA usada sesión tras sesión, no varios agentes distintos en paralelo.

Esa misma regla es lo que permitió que una auditoría completa, corrida por un agente que no había
participado en ninguna decisión anterior, pudiera distinguir correctamente entre un hallazgo genuinamente
nuevo y una decisión ya tomada y documentada (aceptada, pospuesta, o descartada) — sin necesitar que nadie se
lo explicara verbalmente primero.

## La lección meta

Ningún patrón de este documento se escribió antes de que el problema real apareciera — igual que en los dos
casos anteriores. Lo que este tercer caso confirma, con una forma de proyecto todavía más distinta que la del
segundo (una aplicación de consola sin interfaz, sin multi-repo, con concurrencia entre instancias del mismo
proceso como problema central), es que el principio rector del framework no depende del tipo de aplicación:
la mitad de los hallazgos de aquí — verificar contra un sistema real en vez de confiar en una asunción
heredada, dejar que un proceso largo sea resumible por diseño, sincronizar reglas de negocio entre agentes
que no se coordinan entre sí — son variaciones del mismo problema genérico que ya aparecía en los dos casos
anteriores con mecanismos distintos. Eso es evidencia de que el problema es real y recurrente en cualquier
proyecto donde un LLM colabora de forma sostenida, no de que cada proyecto necesita descubrir sus propias
reglas desde cero.
