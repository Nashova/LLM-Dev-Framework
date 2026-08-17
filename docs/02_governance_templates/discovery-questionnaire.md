# Cuestionario de descubrimiento — antes de escribir la primera línea de arquitectura

Adaptado de un cuestionario de descubrimiento usado en un proyecto real, generalizado para cualquier stack/cliente. Úsalo al arrancar un proyecto nuevo — la respuesta a cada pregunta determina secciones enteras de `Docs/02_technical_architecture/`, así que vale la pena resolverlas explícitamente ANTES de empezar a generar código o documentación, en vez de descubrirlas a mitad de camino.

## 1. Naturaleza del producto
¿Es una aplicación operativa interna, un producto SaaS multi-tenant, un sitio/landing de conversión, un portal corporativo, un microservicio, una integración entre sistemas existentes? La respuesta cambia radicalmente qué tan importante es cada una de las secciones siguientes.

## 2. Identidad visual / branding
¿Hay activos de marca existentes (logos, brandbook)? Si no, definir: paleta de colores, tono visual (minimal, corporativo, playful), y si hay requisitos de white-labeling (¿el mismo producto se despliega para distintos clientes con distinta marca?).

## 3. Flujo de valor principal
¿Cuál es el "happy path" — la secuencia de pasos que un usuario real sigue para obtener el valor central del producto? Todo lo demás (administración, configuración, edge cases) es secundario a esto y debería tratarse como tal en el orden de construcción.

## 4. Modelo de datos
¿Qué entidades se gestionan? ¿Hay datos existentes que migrar, o se diseña el esquema desde cero? Si hay migración de datos, esto determina gran parte del riesgo inicial del proyecto — vale la pena dimensionarlo temprano, no descubrirlo a mitad de la implementación.

## 5. Infraestructura disponible
- **Cloud administrado** (AWS, Azure, GCP) — ¿ya hay una cuenta/suscripción, o hay que aprovisionar desde cero?
- **On-premise / VPS** — Linux o Windows, ¿con o sin contenedores?
- **Serverless / Edge** (Vercel, Netlify, Cloudflare Workers, Supabase) — típicamente el camino de menor fricción operativa si el caso de uso encaja.
- **Sin decidir todavía** — evaluar según: carga esperada, presupuesto, capacidad del equipo cliente para operar infraestructura (¿tienen a alguien que pueda hacer mantenimiento de servidor, o necesitan cero-ops?), y urgencia del lanzamiento.

**Si el proyecto va a correr en un host/red que NO es dedicado exclusivamente a este proyecto** (un servidor compartido con otras aplicaciones del cliente, una red corporativa con proxy/firewall de inspección): pregúntalo explícitamente y documéntalo en `architecture.md` desde el día 1. Esto es una fuente real y recurrente de incidentes difíciles de diagnosticar (conflictos de puerto con vecinos, CLIs que no pueden autenticar por un firewall con inspección TLS) — ver el caso real documentado en `examples/case-study-admin-console.md`.

## 6. Despliegue y proxy
¿Existe ya un servidor web (nginx, IIS, Apache) delante de la aplicación, o hay que provisionar uno? ¿Se requiere CI/CD automatizado, o el despliegue es manual/asistido en esta fase?

## 7. Control de acceso (RBAC)
¿Qué niveles de acceso se requieren? Si la respuesta es "todavía no lo sabemos con precisión", diseñar con la premisa de que VA a crecer en granularidad con el tiempo (casi siempre pasa) — ver `docs/03_architecture_patterns/rbac-cascade.md` para un patrón que absorbe ese crecimiento sin reescribir el modelo entero cada vez.

## 8. Conectividad externa
¿Necesita conectarse a bases de datos remotas, APIs de terceros, o servicios internos del cliente vía SSH/VPN? Cada integración externa es una superficie de fallo adicional que vale la pena mapear temprano (¿qué pasa si ese servicio externo está caído? ¿hay reintentos, hay un plan B?).

## 9. Concurrencia y tiempo real
¿Se espera alta concurrencia? ¿Se requiere WebSocket u otro mecanismo de tiempo real (notificaciones push, actualización en vivo de la UI)?

## 10. Cumplimiento normativo
¿Hay requisitos de cumplimiento (protección de datos, auditoría, retención de logs) impuestos por el cliente o por el sector en el que opera? Esto afecta decisiones de arquitectura (dónde se pueden alojar los datos, qué se debe auditar) que son costosas de retrofit si se descubren tarde.

## 11. Herramienta(s) de IA que va(n) a trabajar en el proyecto
¿Claude Code, Cursor, Copilot, Gemini, más de una? Esto determina qué nombre de archivo usa `AGENT_GUIDE.md` (ver la tabla en ese documento) y si hace falta mantener sincronizadas varias copias.

## 12. Proveedor de control de versiones
¿GitHub, GitLab, Azure DevOps, Bitbucket, algo interno? Esto determina qué versión de `scripts/ship.sh` (o su lógica de creación de PR) aplica sin modificación y cuál necesita el fallback de API REST genérica — ver `scripts/ship.sh` del framework.
