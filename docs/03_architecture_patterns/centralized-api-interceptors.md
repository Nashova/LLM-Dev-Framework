# Patrón: instancia HTTP única con interceptores centralizados

Aplica a cualquier frontend que consuma una API con autenticación por token (JWT, sesión) desde múltiples componentes.

## El problema

Un LLM generando código frontend suele inyectar el token de autenticación a mano en cada llamada individual:

```javascript
axios.get('/api/data', { headers: { Authorization: `Bearer ${token}` } })
```

Esto funciona hasta que el token expira o el backend responde `401`: sin un punto central que reaccione a ese caso, cada componente falla de forma distinta (silenciosamente, con un error genérico, o dejando al usuario en una pantalla rota) según qué tan completo haya sido el manejo de errores de esa llamada en particular.

## El patrón: una sola instancia exportada, nunca instancias nuevas

Todo el tráfico HTTP del frontend hacia el backend pasa por una única instancia central (ejemplo: `src/services/api.js`), nunca por `fetch` crudo ni por instancias nuevas de `axios`/`fetch` creadas ad-hoc en un componente.

1. **Inyección automática del token**: un interceptor agrega el header de autenticación a cada request saliente — ningún componente lo hace a mano.
2. **Reacción centralizada a `401`**: si el servidor responde `401 Unauthorized`, el interceptor lo captura globalmente, limpia la sesión local y redirige a `/login` — un solo lugar decide qué pasa cuando la sesión expira, en vez de que cada componente lo maneje (o no lo maneje) por su cuenta.

## Regla práctica

- Prohibido usar `fetch` crudo o crear una instancia nueva de `axios` fuera de la instancia centralizada.
- Toda petición HTTP pasa por la instancia central para garantizar que la inyección de token y la reacción a `401` apliquen siempre, sin excepción por componente.

## Ejemplo real (caso A)

La reactividad de sesión del caso A (revocar acceso en caliente cuando cambian los permisos de un usuario vía WebSocket) depende de que exista un único punto donde reaccionar a una sesión inválida — si cada componente manejara sus propias llamadas HTTP, la lógica de "cerrar sesión y redirigir" habría tenido que duplicarse en cada uno, con el riesgo real de que alguno quedara sin cubrir.

## Checklist corto

- [ ] ¿Existe una única instancia HTTP exportada que todo el frontend usa?
- [ ] ¿El token se inyecta en un interceptor, no a mano en cada llamada?
- [ ] ¿Una respuesta `401` en cualquier request dispara el mismo flujo de cierre de sesión, sin depender de que cada componente lo implemente?
