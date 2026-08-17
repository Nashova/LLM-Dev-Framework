# Patrón: repo raíz orquestador + N repos de código independientes

Cuándo un proyecto no es un monorepo ni un solo repositorio, sino un repo "raíz" que solo versiona documentación/orquestación mientras cada aplicación real vive en su propio repositorio Git independiente — y qué hay que hacer distinto en la forma de trabajar con un LLM cuando la arquitectura es así.

## Cuándo aplica

Un sistema compuesto por varias aplicaciones/servicios que:
- Se despliegan, versionan y ramifican de forma independiente (cada uno con su propio ciclo `development → staging → main`, o el que use el proyecto).
- Comparten un espacio de documentación/coordinación común, pero ese espacio **no debe contener código de ninguna aplicación** — solo `README`, configuración de orquestación, y la documentación transversal.

Ejemplo real (caso B): un repo raíz que solo rastrea `README.md`, `.gitignore`, configuración de skills/agentes y la carpeta de documentación completa; media docena de aplicaciones (API, frontend, autenticación, dos motores de reportes) cada una en su propio repositorio anidado, con su propio historial de ramas.

## La trampa central: un worktree no se comporta igual para todo

Si el repo raíz se trabaja usando `git worktree` (una copia de trabajo por sesión/tarea, para no pisar el checkout principal), aparece una asimetría que no es intuitiva y que **rompe la premisa de "todo lo que veo en disco es lo que hay"**:

- Los directorios de las aplicaciones anidadas aparecen **vacíos** en cualquier worktree que no sea el checkout principal — porque son repos Git independientes, no contenido versionado por el repo raíz, y `git worktree` solo materializa lo que el repo raíz sí versiona.
- La documentación (si vive dentro del repo raíz, como debería) **sí** está completa y versionada en cada worktree — es contenido real del repo raíz, no un repo anidado.

Esta asimetría es la fuente de un error concreto y repetible: escribir/editar documentación asumiendo que "como los directorios de código están vacíos aquí, mejor trabajo en el checkout principal" — y terminar guardando cambios de documentación en el checkout principal (potencialmente en la rama por defecto, `main`/`master`) en vez del worktree de la sesión activa. Ese error pasó dos veces en el mismo proyecto real (caso B) a pesar de estar documentado la primera vez — la memoria de "ya lo corregí antes" no sustituye la verificación en el momento.

**Regla práctica:**
1. Antes de escribir cualquier archivo de documentación en una sesión que usa worktrees, correr `git worktree list` y confirmar la ruta absoluta del worktree activo — no asumir que es el directorio de trabajo por defecto de la herramienta.
2. Escribir el código de las aplicaciones **siempre** en el repo del contenedor correspondiente (nunca en el repo raíz), y la documentación **siempre** en el worktree activo del repo raíz (nunca en el checkout principal, salvo que la sesión sea literalmente sobre el checkout principal).
3. Si algo se guardó por error en el lugar equivocado: revertir (`git checkout --` / `git restore`) el archivo tocado en el lugar equivocado ANTES de reescribirlo en el lugar correcto — no dejar ambos, ni asumir que "ya no importa porque ya está en el lugar bueno también" (deja el checkout principal con un diff fantasma que alguien va a tener que investigar después).
4. Si el mismo tipo de error ya pasó una vez en el proyecto, no confiar solo en la memoria (de la herramienta de IA o del documento de incidentes) para no repetirlo — la señal más confiable de que algo se guardó en el lugar equivocado suele venir de afuera (un visor de archivos del usuario que no encuentra la ruta, un `git status` en el lugar que debería estar limpio y no lo está), no de "recordarlo mejor" la próxima vez.

## La segunda trampa: la rama activa no siempre tiene todo

En un repo con ciclo de promoción por ramas (`development → staging → main`), el checkout local de un repo anidado puede estar posicionado en cualquiera de esas ramas — y no hay garantía de que sea la que tiene el trabajo más reciente. Leer el disco tal cual está da una respuesta **falsa** a preguntas como "¿esto ya está implementado?" si el trabajo real vive en una rama distinta a la que está activa.

**Regla práctica:** antes de afirmar que algo no existe o no está implementado en un repo con este patrón, verificar explícitamente con `git show <rama>:<ruta>` o `git log <rama> --oneline -- <ruta>` en las ramas relevantes — no basta con mirar el árbol de archivos de la rama actualmente activa.

## Cómo documentar esto en `architecture.md`

Si el proyecto sigue este patrón, decláralo explícitamente y temprano en (template) `Docs/03_governance_and_guidelines/architecture.md` (sección de estructura de repos), incluyendo:
- Qué contiene el repo raíz exactamente (nunca "todo menos código", sé literal: qué archivos/carpetas rastrea).
- La lista de repos anidados, su stack, y su propio ciclo de ramas si difiere del general.
- La advertencia explícita de la asimetría de worktrees si la herramienta de IA del equipo los usa.
- Cualquier caso confirmado de "trabajo real que solo vive en una rama no-default" — para que no se tenga que redescubrir cada vez que alguien pregunta si algo existe.
