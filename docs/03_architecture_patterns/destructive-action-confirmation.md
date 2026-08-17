# Patrón: confirmación para acciones destructivas o irreversibles

Cuándo y cómo pedir confirmación antes de una acción que borra datos permanentemente, sobrescribe algo en producción, o rota una credencial compartida — de forma que sea difícil dispararla por accidente, sin volver el flujo tan pesado que la gente empieza a hacer click sin leer.

## Cuándo aplica este patrón

No todo lo que borra algo necesita este nivel de fricción. La vara: **¿es fácilmente reversible?** Borrar un registro que tiene una papelera/soft-delete, o un archivo del que hay más copias, no necesita más que un `confirm()` simple. Esto es para lo que de verdad no tiene vuelta atrás: sobrescribir una base de datos en vivo, borrar el único respaldo que existe, rotar una credencial que otros sistemas ya están usando.

## Las capas del patrón (de afuera hacia adentro)

### 1. Visibilidad — antes de la lógica de negocio

Si la acción solo debería estar disponible para un subconjunto de usuarios, el control que la dispara ni siquiera debería RENDERIZARSE para el resto. Esto no es seguridad real (el backend tiene que validar igual, ver capa 4) — es UX: reduce la superficie de "¿qué es este botón?" para quien no debería tocarlo, y reduce el riesgo de que alguien lo descubra por accidente explorando la interfaz.

### 2. Información completa antes de pedir confirmación

El modal/pantalla de confirmación debe mostrar TODA la información que alguien necesita para verificar que está a punto de afectar la cosa correcta — no un genérico "¿estás seguro?". Concretamente: qué entidad exacta se va a afectar, a qué sistema/servidor se conecta, cuándo fue el último estado bueno conocido (si aplica), y qué se pierde exactamente si se procede. La pregunta que hay que poder responder mirando el modal, sin tener que ir a verificar en otro lado: *"¿esto es lo que yo creía que iba a pasar?"*

### 3. Confirmación por escritura exacta, no por click

Para el nivel más alto de riesgo, un solo click de "Sí, confirmar" es demasiado fácil de disparar sin leer (el dedo ya sabe dónde está ese botón de tanto usar la pantalla). El patrón más efectivo: pedir que la persona **escriba** el nombre exacto de la entidad que va a afectar (sensible a mayúsculas/minúsculas) antes de habilitar la acción real. Esto obliga una pausa cognitiva genuina — es mucho más difícil escribir mal un nombre por descuido que hacer click de más.

Detalles de implementación que importan:
- El campo de texto NO debe aceptar autocompletado del navegador/gestor de contraseñas (un autocompletado exitoso anula todo el propósito del ejercicio).
- La comparación debe ser exacta (`===`), no case-insensitive — si el nombre real tiene mayúsculas, la persona tiene que reproducirlas.

### 4. Estilo visual invertido a propósito

El botón que CANCELA la acción se ve como el botón normal y prominente de la interfaz. El botón que EJECUTA la acción (una vez habilitado por la capa 3) se estiliza como texto plano, sin fondo ni borde — deliberadamente el elemento MENOS visualmente dominante de la pantalla. La intención: que el camino de menor resistencia visual sea cancelar, no confirmar. Un usuario que llega a esa pantalla por error (click perdido, tab equivocado) tiene que hacer un esfuerzo activo para encontrar y accionar el botón real, en vez de que sea lo primero que su vista/mano encuentren.

### 5. Validación de la confirmación TAMBIÉN en el backend

La UI puede tener un bug, alguien puede llamar al endpoint directo (Postman, un script, una integración futura). La condición de confirmación (el nombre exacto escrito) se vuelve a validar del lado del servidor antes de ejecutar — nunca confiar en que "si llegó la petición es porque el frontend ya validó bien". Esto es defensa en profundidad: dos validaciones independientes de la misma condición, no una validación duplicada porque no se confía en ninguna de las dos por separado.

### 6. Auditoría del intento, exitoso o no

Cada intento de ejecutar la acción (haya tenido éxito o haya fallado a mitad de camino) queda registrado: quién, cuándo, sobre qué, y si funcionó o no. Ver `audit-logging.md` en esta misma carpeta para el patrón completo — la razón de auditar INCLUSO los intentos fallidos es que un fallo a mitad de camino de una operación destructiva puede dejar el sistema en un estado intermedio que alguien va a necesitar diagnosticar después, y "¿alguien intentó esto y falló?" es la primera pregunta en ese diagnóstico.

## Ejemplo real (caso A)

Un botón de "Restaurar" que sobrescribe una base de datos en vivo desde un respaldo. Solo visible para el rol más alto (capa 1). El modal muestra destino, motor de base de datos, servidor SSH, fecha del respaldo y tamaño (capa 2). El botón real de restaurar solo se habilita al escribir el nombre exacto de la base de datos (capa 3). "Cancelar" es un botón normal; "Restaurar desde este dump" es texto plano gris que se pone rojo solo cuando está habilitado (capa 4). El backend vuelve a comparar el nombre contra el real antes de ejecutar (capa 5). Cada intento, exitoso o fallido, se audita en una tabla separada del historial normal de operaciones (capa 6) — separada a propósito, porque mezclar "historial de creación de respaldos" con "historial de restauraciones" en la misma tabla hubiera mezclado dos operaciones con semántica de riesgo completamente distinta.
