# Patrón: frontend sin enrutador central que editar (Zero-Routing)

Aplica a cualquier SPA (React, Vue, Angular) donde varios agentes/desarrolladores van a agregar pantallas nuevas con frecuencia, sin coordinarse en tiempo real entre sí.

## El problema

En una SPA tradicional, agregar una pantalla nueva significa editar un archivo de enrutamiento central (`App.jsx`, `routes.jsx`, el router de Vue/Angular). Cuando varios agentes trabajan en paralelo, esto produce:
1. **Colisiones de merge** — dos agentes insertando una ruta nueva en el mismo archivo, en la misma zona, al mismo tiempo.
2. **Sintaxis rota** — un LLM que inyecta un import y una ruta a mitad de un archivo gigante rompe la estructura con más frecuencia que un humano, porque no tiene el archivo completo "en la cabeza" al editarlo.
3. **Tokens gastados en contexto irrelevante** — para agregar un submódulo, el agente termina leyendo el árbol de rutas completo solo para encontrar dónde insertar una línea.

## El patrón: el frontend reacciona a un catálogo, no a un archivo editado a mano

1. **Ruta comodín (catch-all)**: el archivo central de rutas define una única ruta parametrizada (ej. `<Route path="/s/:sectionId/:appCode/:moduleCode" element={<SectionLayout />} />`) y no vuelve a tocarse al agregar módulos.
2. **Catálogo de módulos**: la navegación se carga desde una base de datos o un JSON, no desde rutas hardcodeadas.
3. **Registro de módulos (Module Registry)**: un diccionario central (`ModuleRegistry.js`, string → componente) mapea el código de módulo de la URL al componente correspondiente. Agregar un módulo nuevo es: escribir el componente + agregar una línea al registro — nunca tocar el archivo de rutas.

## Regla práctica

- **Prohibido modificar el archivo de rutas** para agregar un módulo nuevo — si un cambio de pantalla requiere tocarlo, es señal de que el catch-all o el registro están mal diseñados, no de que esta vez sea una excepción válida.
- Registrar el módulo nuevo únicamente en `ModuleRegistry.js` (o equivalente) — el enrutador lo descubre solo.

## Ejemplo real (caso A)

El caso A construyó decenas de módulos administrativos durante meses con múltiples sesiones de IA trabajando en paralelo sin coordinación en tiempo real. Antes de adoptar el registro central, cada módulo nuevo tocaba el enrutador y generaba fricción de merge; después, agregar un módulo dejó de tocar ningún archivo compartido con otro módulo en desarrollo simultáneo.

## Checklist corto

- [ ] ¿El archivo de rutas define un catch-all parametrizado, en vez de una ruta explícita por módulo?
- [ ] ¿Agregar un módulo nuevo implica tocar únicamente su propio componente + una línea en el registro?
- [ ] Si alguien "necesita" tocar el enrutador para un módulo nuevo, ¿se investigó por qué el catch-all no lo cubre, en vez de hacer la excepción?
