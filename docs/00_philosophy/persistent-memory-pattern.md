# Memoria persistente entre sesiones: qué guardar, cómo, y por qué sigue habiendo que verificar

Complementa `collaboration-style.md` §2 ("verifica antes de recomendar desde memoria"). Ese principio asume que existe algo llamado "memoria" de una sesión a otra — este documento describe cómo construir esa memoria bien, sea con un mecanismo nativo de la herramienta de IA o a mano.

## El problema que resuelve

Sin ningún mecanismo de persistencia, cada sesión nueva con un LLM empieza en cero: quién es el usuario, cómo prefiere trabajar, qué se decidió la semana pasada, qué proyecto es este exactamente. Reconstruir eso desde el código y la documentación versionada es posible pero lento, y hay una categoría de información que **no vive en el código en absoluto** — preferencias del usuario, feedback sobre cómo colaborar, estado de conversaciones/negociaciones en curso con el cliente — que se pierde por completo sin un mecanismo dedicado.

## Categorías de memoria (tipado, no un blob de notas)

Un archivo único de "notas" que crece sin estructura se vuelve inmanejable rápido y mezcla cosas con ritmos de verificación muy distintos. Separar por tipo:

- **Identidad/perfil del usuario** — rol, nivel de experiencia en el dominio, responsabilidades. Cambia poco.
- **Feedback de colaboración** — correcciones ("no hagas X") **y confirmaciones** ("sí, ese enfoque no obvio funcionó, seguí así") — ver `collaboration-style.md` §5, ambas son igual de valiosas y ambas se pierden igual de fácil si no se registran deliberadamente.
- **Estado de proyectos/iniciativas en curso** — quién está haciendo qué, por qué, para cuándo. Cambia rápido — cualquier fecha relativa mencionada por el usuario ("el jueves", "la semana que viene") debe guardarse convertida a fecha absoluta, porque una fecha relativa pierde sentido en cuanto se lee en una sesión futura.
- **Punteros a sistemas externos** — dónde vive qué (el tablero de incidentes, el canal de feedback, el proyecto de tracking) — no el contenido de esos sistemas, solo dónde encontrarlo.

Cada categoría tiene un formato mínimo reusable: qué se afirma, **por qué** (la razón que dio el usuario, el incidente que lo motivó — sin el "por qué" una regla guardada es difícil de juzgar en un caso límite futuro), y cómo aplicarla.

## Un índice corto + un archivo por tema, no un archivo gigante

El índice es una lista de una línea por entrada (título + gancho de una frase) — se carga siempre, tiene que ser barato de leer completo cada sesión. El detalle completo de cada entrada vive en su propio archivo, enlazado desde el índice, y los archivos se enlazan entre sí por nombre cuando se relacionan. Esto escala mejor que un archivo único porque cargar "todo lo que se sabe" en cada sesión se vuelve caro rápido, mientras que cargar el índice + solo los archivos relevantes al tema de la sesión actual no.

Confirmado por segunda vez en un proyecto con forma muy distinta a la que originó el patrón
(el caso C, un motor de consola sin la escala multi-repo del caso B): el mismo esquema de índice
corto + un archivo por tema, con categorías tipadas (perfil del usuario, feedback de colaboración, estado
de proyecto, punteros a otros sistemas), aceleró el arranque de sesiones nuevas de la misma forma —
evidencia de que el patrón no depende de la escala del proyecto.

## La regla de verificación no es opcional, ni con memoria nativa de buena calidad

Este es el punto que un mecanismo de memoria bien diseñado NO resuelve por sí solo: una entrada de memoria es una fotografía de lo que era cierto cuando se escribió, no una garantía de lo que es cierto ahora. Un hallazgo real (ver `examples/case-study-multi-repo-ecosystem.md`): una entrada de memoria decía "esto ya se corrigió una vez" — cierto cuando se escribió — y confiar en esa afirmación sin re-verificar el estado real del disco llevó a repetir exactamente el mismo error que la memoria decía haber resuelto.

**Regla práctica**, en orden de exigencia creciente:
- Antes de **mencionar** algo recordado ("la memoria dice que X"), no hace falta verificar — es solo contexto conversacional.
- Antes de **construir sobre** algo recordado (una ruta de archivo, el nombre de una función, un estado ya resuelto), verificar contra el estado real — grep, `git status`, leer la línea real — especialmente si la acción que se va a tomar depende de que eso siga siendo cierto.
- Si la memoria resulta estar desactualizada, corregirla o borrarla en el momento, no dejarla ahí "por si acaso" — una memoria que se sabe falsa y no se corrige es peor que no tener memoria.

## Para herramientas sin mecanismo de memoria nativo

El patrón no depende de que la herramienta tenga memoria automática. Un archivo `MEMORY.md` versionado o gitignored (según si el contenido es del proyecto o personal del operador) en la raíz del proyecto, con la misma estructura (índice + categorías tipadas), y una instrucción explícita en `AGENT_GUIDE.md` de "leer este archivo al empezar la sesión, proponer una entrada nueva al cerrar un hallazgo importante" cumple el mismo rol — más lento porque depende de que alguien (LLM o humano) se acuerde de actualizarlo, pero estructuralmente idéntico.
