# Patrón: auditoría de acciones sensibles

Un registro persistente de "quién hizo qué y cuándo" para acciones que alguien (soporte, seguridad, el propio equipo) va a necesitar reconstruir después — separado del historial funcional normal del sistema.

## Por qué una tabla separada, no reusar el historial existente

Es tentador reusar una tabla de historial que ya existe (ej. "historial de operaciones") para registrar también los intentos de una acción sensible relacionada. Resistir esa tentación: las dos cosas tienen semántica distinta (una es "qué se produjo", la otra es "quién intentó usar/afectar lo producido"), y mezclarlas en las mismas columnas obliga a columnas que significan cosas distintas según la fila — una fuente de bugs sutiles y de consultas confusas más adelante.

## Qué registrar como mínimo

- **Quién** — el usuario autenticado que disparó la acción (nunca null si hay un usuario autenticado disponible; si el sistema permite acciones no-autenticadas sensibles, esa es una señal de que falta control de acceso antes de pensar en auditoría).
- **Cuándo** — timestamp del intento, no solo del resultado final.
- **Sobre qué** — una referencia estable al objeto afectado. Si existe la posibilidad de que el objeto original se borre o cambie de nombre después, guardar también un snapshot del dato relevante en el momento (ej. el nombre exacto de la entidad afectada) — no depender solo de una foreign key que podría apuntar a algo que ya no es lo mismo.
- **Resultado** — éxito o falla, y si falló, el detalle del error. Auditar SOLO los éxitos deja un punto ciego exactamente donde más se necesita: cuando algo salió mal a mitad de camino.

## La foreign key hacia el objeto auditado normalmente NO debe ser opcional

Si la tabla de auditoría referencia al objeto que originó la acción (ej. "qué respaldo se restauró"), esa referencia debería ser obligatoria (`NOT NULL`), no opcional. Esto tiene una consecuencia de diseño importante: si en algún momento alguien intenta borrar el objeto referenciado, la base de datos va a rechazarlo por la constraint de foreign key — lo cual es CORRECTO, no un bug a silenciar. Borrar el objeto original dejaría el registro de auditoría huérfano (apuntando a algo que ya no existe), lo cual derrota el propósito de tener auditoría en primer lugar. Si aparece esta tensión (algo quiere borrar un objeto que tiene auditoría asociada), la resolución correcta casi siempre es: bloquear ese borrado explícitamente con un mensaje claro, no relajar la constraint.

## No hace falta una UI de consulta desde el día 1

Registrar la auditoría en una tabla nueva no obliga a construir de inmediato una pantalla para verla — eso puede esperar hasta que alguien de verdad la necesite (soporte investigando un incidente, una auditoría de seguridad real). Lo que sí hay que tener desde el día 1 es el REGISTRO en sí — reconstruir retroactivamente qué pasó, sin haberlo registrado en el momento, casi nunca es posible.
