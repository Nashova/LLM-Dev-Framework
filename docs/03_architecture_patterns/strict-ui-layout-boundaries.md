# Patrón: límites estrictos de layout (sin scroll global)

Aplica a cualquier SPA pensada como una "consola" o panel administrativo — una interfaz que se comporta más como una aplicación de escritorio que como una página web que se desplaza verticalmente.

## El problema

Un LLM que se encuentra con contenido desbordando su contenedor tiende a resolverlo agregando `overflow-y-scroll` o una altura fija al azar en el contenedor que tiene más cerca, en vez de preguntarse por qué desborda. El resultado acumulado de varias de estas correcciones puntuales es una interfaz con barras de scroll dobles/anidadas, layout que rompe en tamaños de pantalla no probados, y una experiencia visual inconsistente entre módulos.

## El patrón: contención explícita, scroll solo donde se declara

1. **Prohibición de scroll global**: el contenedor raíz (`body`, `main`) tiene `overflow: hidden` explícito — la aplicación completa nunca se desplaza como una página, solo sus áreas internas designadas.
2. **Flexbox con `min-h-0`**: los contenedores hijos usan `flex-1 min-h-0` para respetar la altura de su padre en vez de empujar el layout hacia abajo — el gotcha clásico de Flexbox es que sin `min-h-0` un hijo con contenido largo ignora la altura del padre y fuerza el desbordamiento que se intentaba evitar.
3. **Scroll local, no global**: las únicas áreas autorizadas para `overflow-y-auto` son contenedores de datos extensos (el cuerpo de una tabla, un visor de logs) — nunca el layout completo. Encabezados y controles quedan fijos (`sticky top-0` o fuera del contenedor con scroll).

## Regla práctica

- La pantalla principal de un módulo nunca debe generar scroll global hacia abajo.
- Usar `flex-1 min-h-0` para contener contenedores con contenido variable, no una altura fija adivinada.
- Las cabeceras de tabla (`<thead>`) van `sticky top-0` dentro de su contenedor con scroll local.

## Ejemplo real (caso A)

Varios módulos del caso A (historiales, bitácoras, listados) mostraban tablas potencialmente largas dentro de una consola de una sola pantalla. El criterio de "cero scroll global, solo el cuerpo de la tabla se desplaza, con encabezado fijo" se volvió la convención estándar de todo módulo nuevo — evita que cada pantalla nueva reinvente su propia solución de contención, generalmente peor que la anterior.

## Checklist corto

- [ ] ¿El contenedor raíz tiene `overflow: hidden` explícito?
- [ ] ¿Los contenedores flex que deben contener contenido variable usan `min-h-0`, no solo `flex-1`?
- [ ] ¿El único scroll visible está en el cuerpo de datos, con encabezado/controles fijos?
