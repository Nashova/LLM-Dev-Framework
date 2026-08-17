# Caso B: ecosistema multi-repo en un sector regulado

> Caso de estudio **anonimizado**. Los tres casos de `examples/` provienen de sistemas reales, pero se
> publican sin nombres de sistema, cliente, sector, infraestructura ni identificadores internos. Lo que se
> conserva es el mecanismo del incidente y la regla que nació de él — que es lo único reusable. Ver
> [`README.md`](../README.md) para el criterio de anonimización.

Segundo caso que retroalimenta este framework — no reemplaza al [caso A](case-study-admin-console.md), lo
complementa y sirve para validar qué tan generales son de verdad los patrones. Distinto stack (backend MVC
en un lenguaje interpretado + SPA + dos motores de reportes, en vez de backend Python + SPA), distinto tipo
de negocio (un sector con cumplimiento regulatorio hacia un sistema externo, en vez de soporte técnico
interno), y sobre todo, distinta **forma de repositorio**: no un monorepo único, sino un repo raíz de
documentación orquestando varios repos de código independientes. Varios de los hallazgos de aquí solo
aparecieron por esa diferencia estructural — es exactamente el tipo de cosa que un framework basado en un
solo caso no puede anticipar.

## La forma del proyecto

Un sistema de cumplimiento regulatorio con **media docena de aplicaciones independientes** (una API, un
frontend SPA, un servicio de autenticación federada, un motor de reportes heredado y un microservicio nuevo
de reportes que lo reemplazaba gradualmente) más un repo raíz que **no contiene código**, solo documentación
y orquestación — cada aplicación vive en su propio repositorio Git, con su propio ciclo de ramas
`development → staging → main`. Ningún archivo de "arquitectura general" describe esto correctamente si
asume "un repo, un `.git`" — hubo que documentarlo explícitamente como su propio patrón (ver
[`multi-repo-orchestrator.md`](../docs/03_architecture_patterns/multi-repo-orchestrator.md), que nace
directamente de este proyecto).

## Incidentes reales que dieron forma a las reglas nuevas

- **El mismo error de worktree, dos veces, en el mismo proyecto.** Trabajando en una sesión con
  `git worktree`, la documentación se guardó por accidente en el checkout principal en vez del worktree
  activo de la sesión — porque los directorios de las aplicaciones SÍ aparecen vacíos en un worktree (son
  repos anidados independientes), pero la carpeta de documentación SÍ está versionada completa en cada
  worktree, y esa asimetría no es intuitiva. Se corrigió la primera vez, se documentó la lección... y volvió
  a pasar en una sesión posterior, porque la lección vivía en la memoria de una sesión anterior y no se
  re-verificó contra el estado real antes de escribir. La corrección definitiva no fue "recordarlo mejor" —
  fue que el propio visor de archivos del usuario reportara "no puedo leer este archivo" al intentar abrirlo,
  una señal externa que forzó la verificación. Ver
  [`multi-repo-orchestrator.md`](../docs/03_architecture_patterns/multi-repo-orchestrator.md) para el patrón
  y la regla concreta que evita depender solo de la memoria.
- **Una rama activa que no es la rama con el trabajo real.** La integración del microservicio nuevo de
  reportes vivía completa en las ramas `development`/`staging` de dos repos distintos, pero el checkout local
  activo apuntaba a `main`, que no la tenía. Preguntar "¿esto ya está implementado?" leyendo solo el disco
  daba una respuesta falsa negativa. La regla que salió de esto: antes de afirmar que algo no existe en un
  proyecto con ramas de promoción, verificar con `git show <rama>:<ruta>` o `git log <rama> --oneline`, nunca
  asumir que la rama activa tiene todo.
- **Un gap de configuración que solo existe en el pipeline de CI, no en el código de la aplicación.** Ese
  mismo microservicio tenía su variable de conexión cableada en el pipeline de CI solo para los ambientes de
  desarrollo y staging — el bloque de despliegue a producción nunca la agregó. Nada en el código de la
  aplicación lo revela; solo comparar el pipeline de las tres ramas lo expone. Si esa rama se promueve a
  producción tal cual, el proxy de reportes falla ahí y en ningún otro lado. Este tipo de drift (rama vs.
  rama, no código vs. código) es lo bastante distinto de un bug de código normal como para merecer su propio
  patrón — ver
  [`branch-per-environment-config.md`](../docs/03_architecture_patterns/branch-per-environment-config.md).
- **Una optimización de pipeline, propuesta por otro LLM, que rompía silenciosamente el login de 2 de 3
  ambientes.** Se llevó una conversación completa con un LLM externo diseñando un pipeline de despliegue sin
  downtime para el frontend. La propuesta final sugería "compilar una sola vez y reusar el mismo build en los
  3 ambientes" para ahorrar tiempo — una optimización que suena obviamente correcta. Verificarla contra el
  código real reveló que cada ambiente tenía una configuración de autenticación distinta **compilada dentro
  del bundle** (no en variables de entorno de runtime) — desplegar el build de producción a los otros
  ambientes los habría dejado con credenciales de identidad equivocadas. El LLM externo no tenía forma de
  saber esto sin leer el código real; el error no era del modelo, era de no haber verificado el supuesto
  contra el proyecto concreto antes de aceptar una propuesta que "suena bien en general". La regla concreta:
  antes de aceptar cualquier optimización de "compilar/procesar una sola vez y reusar en N ambientes",
  confirmar explícitamente si la configuración por ambiente es de runtime o si vive horneada en el artefacto
  de build.
- **Una tarea de "preparación de datos de prueba" que apuntaba a una base de datos operativa.** Una tarea
  planeada para dejar limpia una base de datos de pruebas antes de correr la suite hacía
  `DROP DATABASE`/`CREATE DATABASE` contra una cadena de conexión que, en dos de los tres ambientes, **no
  apuntaba a una base de test dedicada** — porque nunca se aprovisionó una. El nombre de la tarea
  ("test setup") no daba ninguna pista del riesgo real. Se reemplazó por un verificador de solo lectura que
  confirma que las tablas de referencia existen, sin crear ni modificar nada. La lección generalizable: un
  nombre de tarea o script que suena inocuo ("setup", "seed", "reset", "limpieza") no es garantía de que lo
  sea — antes de ejecutar cualquier tarea así por primera vez en un ambiente que no sea 100% local y
  descartable, leer qué hace realmente en vez de confiar en el nombre.
- **Botones y flujos conectados en el código que no estaban en uso operativo real.** Más de una vez, código
  completamente funcional (un método de login alternativo, un flujo de digitalización en una ruta secundaria)
  resultó estar presente y conectado, pero no ser parte del uso real del negocio — algo que solo el usuario
  podía confirmar, no algo derivable leyendo el código. Asumir "está en el código, luego se usa" llevó a
  construir sobre una premisa equivocada más de una vez. Se convirtió en regla explícita: código presente no
  es lo mismo que funcionalidad en uso — ver la regla 8 de
  [`collaboration-style.md`](../docs/00_philosophy/collaboration-style.md).

## Cómo maduró la documentación (y por qué terminó en dos niveles, no uno)

El primer intento fue, igual que en el caso A, un documento único de arquitectura. A diferencia del caso A,
la escala de este proyecto (media docena de aplicaciones, cumplimiento regulatorio, flujos de negocio de
decenas de pasos) lo desbordó rápido — un solo archivo no podía cubrir "todo lo que un LLM necesita saber"
sin volverse inmanejable de navegar o de mantener. La solución que terminó funcionando fue partirlo por
dominio (arquitectura general, modelo de datos, endpoints, servicios/jobs, el flujo de negocio más crítico,
autenticación, frontend, infraestructura, riesgos conocidos — más de una decena de documentos numerados) con
una tabla de ruteo en el documento de entrada ("¿necesitas X? → lee el documento Y") — y, crucialmente,
manteniendo esa base de conocimiento **separada** de la documentación que sí se entrega al cliente como
artefacto formal. Ver [`two-tier-documentation.md`](../docs/00_philosophy/two-tier-documentation.md) y su
plantilla en
[`ai-knowledge-base-template.md`](../docs/02_governance_templates/ai-knowledge-base-template.md) — ambos
nacen directamente de esta experiencia.

En paralelo, apareció una necesidad que el caso A no había expuesto todavía: llevar control de **trabajo
pedido pero no entregado** (requerimientos y proyectos del negocio) sin que se mezclara ni con el catálogo de
incidentes (que es solo para lo que ya se rompió) ni con el CHANGELOG (que es solo para lo ya entregado).
Terminó siendo su propio subsistema con dos tipos de documento (cambio acotado vs. iniciativa multi-fase),
IDs secuenciales, un estado MoSCoW definido por negocio, y una regla explícita de no duplicar en él nada que
ya viviera en otro registro. Ver
[`requirements-tracking-template.md`](../docs/02_governance_templates/requirements-tracking-template.md).

## El asistente de IA mantuvo su propia memoria persistente entre sesiones

Distinto de la documentación versionada en git: la herramienta de IA usada en este proyecto soportaba un
mecanismo de memoria propio, persistente entre sesiones, separado del repositorio — con categorías tipadas
(sobre el usuario, retroalimentación/correcciones y confirmaciones, estado de proyectos en curso, punteros a
sistemas externos) y un índice corto. Esa memoria aceleró mucho el arranque de sesiones nuevas ("¿qué
proyecto es este, cómo prefiere trabajar este usuario, qué se decidió la semana pasada?") — pero también fue
la causa exacta del incidente de worktree repetido: la memoria decía "ya se corrigió esto una vez", y esa
afirmación, sin re-verificar contra el estado real del disco, llevó a repetir el mismo error. Ver
[`persistent-memory-pattern.md`](../docs/00_philosophy/persistent-memory-pattern.md) — el patrón es
generalizable incluso para herramientas sin memoria nativa (un `MEMORY.md` mantenido a mano cumple el mismo
rol, más lento pero igual de válido).

## Protocolos que se automatizaron como triggers en vez de quedar en prosa

El proyecto usaba una herramienta de IA que soporta "skills" — protocolos que se auto-disparan según la forma
de la tarea (no según que el LLM recuerde leer un párrafo). Tres protocolos de alto riesgo (el contexto
esencial del proyecto, el flujo de diagnóstico ante errores, y sobre todo cualquier cambio a los archivos que
generan el output regulatorio hacia el sistema externo) se convirtieron en skills en vez de quedar como
secciones del documento de entrada — porque ese último archivo, ese que genera un output que un sistema
externo va a parsear **por posición de columna**, es exactamente el tipo de cosa donde "el LLM se olvidó de
leer la advertencia" no es una falla aceptable. Ver
[`skills-and-triggers.md`](../docs/03_architecture_patterns/skills-and-triggers.md).

## La lección meta (igual que en el caso A, confirmada por segunda vez)

Ningún patrón de este documento se escribió antes de que el problema real apareciera — cada uno costó una
sesión de confusión o un hallazgo incómodo antes de convertirse en regla. Lo que sí cambió respecto al caso A
es la confianza en que estos patrones no son anécdotas de un proyecto: la mitad de los patrones nuevos de
aquí (memoria persistente, base de conocimiento en dos niveles, skills como triggers) resuelven el mismo
problema genérico — "que el conocimiento ganado por las malas no se pierda entre sesiones" — con mecanismos
distintos según qué herramienta y qué escala de proyecto estaban disponibles. Eso es evidencia de que el
problema es real y recurrente, no de que la solución de un proyecto se puede copiar literalmente al
siguiente.
