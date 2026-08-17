# Cómo colaborar con un LLM sin que la calidad se degrade

Esto no es sobre prompting. Es sobre las decisiones de proceso que determinan si, después de 100 sesiones, el proyecto es más sólido o es un pantano de parches contradictorios.

## 1. Pide criterio, no adivines por el usuario

Un LLM que tiene que elegir entre dos diseños razonables y no está seguro de cuál prefiere el equipo tiene dos caminos: adivinar y seguir, o preguntar y esperar. Adivinar se siente más "productivo" en el momento, pero cuando la decisión es realmente del usuario (afecta UX visible, cambia alcance, o tiene un trade-off que solo el negocio puede pesar), adivinar mal cuesta una ronda completa de retrabajo — y en un proyecto largo, varias rondas de retrabajo silencioso son indistinguibles de progreso lento.

**Regla práctica:** si la decisión es puramente técnica (¿qué patrón de índice uso?, ¿qué nombre de función?), decide y sigue. Si la decisión afecta lo que el usuario ve, cómo se comporta el sistema en un caso límite, o el alcance de lo que se va a construir, pregúntala explícitamente — con opciones concretas, no en abstracto.

*Ejemplo real (caso A):* al construir un botón de "restaurar respaldo" (sobrescribe una base de datos en vivo desde un backup), la pregunta correcta no era "¿implemento la confirmación?" sino "¿el botón de confirmar debe verse como el elemento MENOS visible de la pantalla, o como uno normal?" — una decisión de UX/riesgo que solo el usuario podía pesar, con consecuencias reales si se elegía mal.

*Ejemplo real (caso C):* al diseñar una bandera de "modo permisivo" por cliente para un motor de validación de archivos, ninguna de estas preguntas tenía una respuesta técnica correcta, y las cuatro se hicieron explícitamente con opciones concretas en vez de elegir la que "sonaba razonable": ¿aplica a todos los tipos de archivo o solo a algunos?, ¿un archivo aceptado con errores debe seguir apareciendo en el reporte de errores?, ¿debe cambiar el código de salida del proceso (que un sistema externo monitorea)?, ¿un valor demasiado largo para su campo destino se trunca o se rechaza? Cuatro decisiones de negocio distintas en la misma feature, ninguna adivinada.

## 2. Verifica antes de recomendar desde memoria

Un LLM que trabaja sobre un proyecto por muchas sesiones acumula "memoria" — nombres de funciones, rutas de archivo, decisiones pasadas. Esa memoria es un resumen de lo que fue cierto en un momento dado, no una garantía de lo que es cierto ahora. El código cambia; los recuerdos no se actualizan solos.

**Regla práctica:** antes de actuar sobre algo recordado de una sesión anterior (no solo mencionarlo, sino construir sobre ello), verifica que sigue siendo cierto — greppea el nombre de la función, confirma que el archivo existe, lee la línea real. "La memoria dice que X existe" no es lo mismo que "X existe ahora".

## 3. El primer error real vale más que diez reglas hipotéticas

Es tentador, al empezar un proyecto, escribir un documento de "mejores prácticas" exhaustivo cubriendo cada escenario imaginable. Ese documento envejece mal — la mitad de las reglas nunca aplican, la otra mitad no cubre el problema real que sí va a aparecer.

**Regla práctica:** el catálogo de reglas de seguridad (`change-safety.md` en la plantilla de gobernanza) empieza casi vacío. Cada entrada nace de un incidente real: algo se rompió, alguien investigó la causa raíz, y esa causa raíz — no una versión genérica de ella — se documenta con el síntoma exacto, la causa exacta, y el fix exacto. Un catálogo de 15 incidentes reales vale más que 50 reglas hipotéticas, porque cada una de las 15 va a volver a ser relevante tarde o temprano, y las 50 hipotéticas probablemente no.

## 4. Cuando algo se repite dos veces, hay que escribirlo donde se vaya a leer

No basta con documentar un hallazgo. Hay que documentarlo en el lugar donde alguien (humano o LLM) lo va a estar buscando en el momento exacto en que lo necesita — no en un rincón que nadie vuelve a abrir.

*Ejemplo real (caso A):* un hallazgo sobre por qué el CLI de una nube no podía autenticar en cierta red corporativa se documentó directamente en el catálogo de incidentes de infraestructura, con el síntoma EXACTO que alguien vería (el mensaje de error textual) como punto de entrada — no en un documento aparte de "notas de troubleshooting" que nadie sabría buscar.

## 5. Las correcciones y las confirmaciones son igual de valiosas

Es fácil notar cuando el usuario corrige un error ("no, así no"). Es fácil pasar por alto cuando confirma silenciosamente que un enfoque no obvio funcionó ("sí, exacto, seguí así"). Ambas son señal — la corrección evita repetir un error, la confirmación evita abandonar un enfoque válido la próxima vez que parezca "raro" sin ese contexto.

**Regla práctica:** registra ambas. Un sistema de memoria que solo acumula "no hagas esto" sin acumular también "esto funcionó, aunque no sea obvio por qué" termina siendo excesivamente conservador con el tiempo.

## 6. Ejecutar acciones reversibles sin pedir permiso; pausar antes de las irreversibles

Un LLM que pide confirmación para cada paso es tan improductivo como uno que nunca la pide. La diferencia está en clasificar la acción, no en aplicar una regla uniforme.

**Regla práctica**, en orden de libertad decreciente:
- **Reversible y local** (leer código, correr tests, editar un archivo en una rama de trabajo): actúa sin preguntar.
- **Visible para otros o difícil de revertir** (push a una rama compartida, crear un PR, desplegar a un ambiente compartido): comunica lo que vas a hacer y hazlo, salvo que el usuario haya pedido explícitamente que se confirme cada vez.
- **Destructivo o que afecta datos/credenciales reales** (borrar algo permanentemente, rotar una credencial compartida, sobrescribir producción): pausa y confirma explícitamente, incluso si "técnicamente" el usuario ya autorizó algo parecido antes — la autorización de un alcance no se extiende automáticamente a otro.

## 7. Documentar el hallazgo aunque no se haya pedido

Si en el camino de resolver lo que el usuario pidió aparece un hallazgo real que vale la pena preservar (un gotcha de una herramienta, una inconsistencia en el propio proceso, una regla que el proyecto ya seguía sin haberla escrito nunca), documentarlo en el mismo cierre de la tarea — no esperar a que alguien lo pierda de nuevo y lo vuelva a descubrir por las malas.

## 8. Código presente no es lo mismo que código en uso

Un botón conectado, un endpoint que responde, un flujo completo y funcional en el código no garantizan que el negocio realmente lo esté usando en operación real hoy. Puede ser un método alternativo que se dejó de usar sin borrar el código, una feature detrás de un flag que nunca se activó para el cliente real, o un camino secundario que solo se usó una vez en una migración. Un LLM que lee solo el código no tiene forma de distinguir "esto existe y se usa" de "esto existe y quedó ahí" — son indistinguibles desde el código solo.

**Regla práctica:** antes de recomendar un cambio, o de asumir un comportamiento del sistema, basado en "vi que el código hace X", verifica con el usuario si X es lo que realmente pasa en operación, especialmente si vas a construir algo nuevo sobre esa premisa o si la respuesta cambia el alcance de lo que se va a hacer. Preguntarlo cuesta una frase; construir sobre un supuesto equivocado cuesta una ronda de retrabajo — el mismo cálculo de la regla 1.

*Ejemplo real (caso B):* un método de login alternativo y un flujo secundario de una feature aparecían completos y conectados en el código, pero no formaban parte del uso operativo real del cliente — algo que solo se confirmó preguntando directamente, no derivable de ningún análisis del código en sí.
