# Patrón: catálogo único de estados de carga (Skeleton en vez de spinner genérico)

Aplica a cualquier frontend con llamadas asíncronas frecuentes hacia una API.

## El problema

Cada vez que un LLM implementa una llamada asíncrona nueva, tiende a inventar su propio estado de carga: un texto "Cargando...", un spinner genérico, o directamente un contenedor vacío hasta que llegan los datos. Repetido a través de docenas de pantallas generadas en sesiones distintas, el resultado es una interfaz sin cohesión visual — cada pantalla "carga" de una forma distinta.

## El patrón: un catálogo estricto de componentes de carga

1. **Skeletons para áreas grandes**: cargas de tablas, formularios o tarjetas usan componentes dedicados (`<SkeletonTable />`, `<SkeletonForm />`, `<SkeletonCards />`) que simulan la forma final de la interfaz — reduce el salto visual (Cumulative Layout Shift) cuando los datos reales reemplazan al esqueleto.
2. **Spinners solo para acciones puntuales**: un ícono giratorio dentro de un botón (ej. al confirmar un formulario) es aceptable únicamente para peticiones bloqueantes pequeñas, nunca para cargar una pantalla completa.

## Regla práctica

- No usar barras de progreso ni texto genérico ("Cargando...") para estados de carga de una pantalla completa.
- Una lista/tabla usa `SkeletonTable`; un formulario usa `SkeletonForm` — el catálogo de componentes de skeleton es cerrado y compartido, no uno nuevo por pantalla.

## Ejemplo real (caso A)

Con decenas de módulos administrativos construidos por sesiones de IA independientes, dejar el estado de carga "a criterio de cada sesión" habría producido una consola visualmente inconsistente entre módulos — el mismo problema de fondo que resuelve el patrón de [layout estricto](strict-ui-layout-boundaries.md), aplicado al estado transitorio en vez de al estado final.

## Checklist corto

- [ ] ¿Existe un catálogo cerrado de componentes de skeleton (tabla, formulario, tarjetas) que todo módulo nuevo reutiliza?
- [ ] ¿Los spinners genéricos están limitados a acciones puntuales dentro de un botón, nunca a una pantalla completa?
