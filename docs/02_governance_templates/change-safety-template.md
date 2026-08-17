# Change Safety — Catálogo de incidentes reales

> Copiar a (template) `Docs/03_governance_and_guidelines/change-safety.md` en el proyecto nuevo. Empieza casi vacío — eso es correcto. Ver `docs/00_philosophy/collaboration-style.md` §3 del framework: este documento vale por ser real, no por ser exhaustivo desde el día 1.

## Cómo agregar una entrada nueva

Cada vez que algo se rompe de una forma que no era obvia de antemano y se identifica la causa raíz, agregar una sección numerada nueva **al final** (siguiente número disponible, sin renumerar las anteriores) con este formato:

```markdown
## N. [Título corto que describe el síntoma, no la causa]

**Síntoma real (incidente [fecha]):** [Qué se observó, en términos de lo que alguien vería sin saber la causa todavía. Esto es lo primero que alguien va a leer cuando le pase lo mismo — tiene que ser reconocible.]

**Causa raíz:** [La explicación técnica real. No una generalización — la causa EXACTA que se identificó en este caso.]

**Regla:** [Qué hacer distinto de ahora en adelante. Si hay un comando o chequeo concreto para detectar/prevenir esto, inclúyelo literal, no descrito en prosa.]
```

**Reglas del catálogo:**

- **Nunca renumerar entradas existentes.** Cualquier otro documento que las referencie (`ver change-safety.md §7`) se rompe si renumeras. Agregar siempre al final, aunque el orden temático no sea perfecto.
- **Un incidente real, no un riesgo hipotético.** Si nunca pasó, no entra aquí — entra (si acaso) en una checklist preventiva, que es un documento distinto con un estándar de evidencia distinto.
- **El síntoma antes que la causa, en el título y en la primera línea.** Alguien que llega a este documento buscando ayuda tiene el síntoma en la cabeza, no la causa — todavía no la conoce, por eso está buscando.
- **Si el mismo tipo de incidente vuelve a pasar en un contexto distinto, es una entrada NUEVA que referencia a la vieja, no una edición de la vieja.** Editar destruye el rastro de que el problema no se resolvió completamente la primera vez, que es información valiosa en sí misma.
- **Revisar la sección de checklist al final** (si el proyecto tiene una) cada vez que se agrega una entrada nueva — muchos incidentes, una vez resueltos, se convierten en un ítem de checklist de una línea para prevenir la recurrencia.

## Categorías típicas que van a aparecer con el tiempo

No las crees vacías de antemano — son solo una guía de qué tipo de cosas terminan aquí, para que sepas reconocerlas cuando pasen:

- **Encoding/line-endings** rompiendo algo en un ambiente distinto al de desarrollo (CRLF vs LF es el clásico universal).
- **Caché** (DNS, proxy, CDN) sirviendo contenido viejo después de un deploy.
- **Datos de infraestructura editados a mano** en vez de vía el mecanismo formal (migración, IaC), generando drift silencioso.
- **Secretos expuestos** en un archivo que se pensaba temporal o de desarrollo, y terminó trackeado en git.
- **Recursos compartidos con otro proyecto/equipo en el mismo host** (puertos, memoria) causando fallos que parecen del proyecto propio pero no lo son.
- **Herramientas de CLI que no funcionan en la red/entorno del cliente** (proxies corporativos con inspección TLS, VPNs, firewalls) — cada entorno corporativo tiene sus propias rarezas de red, y vale la pena documentar el diagnóstico rápido para reconocerlas la próxima vez.
- **Permisos de archivos/volúmenes** en contenedores que corren como usuario no-root.

---

<!-- Las entradas reales del proyecto empiezan aquí, numeradas desde 1. -->
