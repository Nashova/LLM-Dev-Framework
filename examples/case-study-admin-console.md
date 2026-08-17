# Caso A: consola administrativa interna con IAs como desarrolladores full-stack

> Caso de estudio **anonimizado**. Los tres casos de `examples/` provienen de sistemas reales, pero se
> publican sin nombres de sistema, cliente, sector, infraestructura ni identificadores internos. Lo que se
> conserva es el mecanismo del incidente y la regla que nació de él — que es lo único reusable. Ver
> [`README.md`](../README.md) para el criterio de anonimización.

**Forma del proyecto**: consola administrativa interna. Backend de API en un framework web de Python,
frontend SPA con enrutamiento del lado del cliente, todo desplegado en contenedores detrás de un proxy
reverso. Agentes de IA escribieron, desde el primer commit, tanto los scripts de infraestructura como la UI
y los endpoints — sin un equipo humano de desarrollo dedicado revisando cada línea antes de llegar a
staging.

## Los retos reales (no hipotéticos)

- **Colisiones en el enrutador del frontend**: varios módulos nuevos tocando el archivo de registro central
  de rutas al mismo tiempo, generando conflictos de merge y, en más de una ocasión, un enrutador roto porque
  una IA insertó una ruta a mitad de un bloque que otra IA estaba modificando en paralelo.
- **Interfaces sin responsividad**: contenedores con `overflow` o alturas fijas inyectadas ad-hoc para
  "resolver" un desbordamiento visual puntual, que rompían el layout en cualquier pantalla de tamaño
  distinto al que se probó.
- **Errores 502 tras cada rebuild de contenedores**: el proxy reverso cacheaba la IP interna vieja del
  contenedor de backend recién reconstruido — ver el patrón completo en
  [`proxy-dns-cache-invalidation.md`](../docs/03_architecture_patterns/proxy-dns-cache-invalidation.md). El
  síntoma llevaba a pánico injustificado ("rompí el código") cuando la causa real era el caché del proxy.
- **Errores 500 al serializar objetos recién borrados**: endpoints `DELETE` devolviendo el objeto del ORM
  después del `commit()`, con sus relaciones de carga diferida (*lazy*) ya expiradas — ver
  [`orm-serialization-safety.md`](../docs/03_architecture_patterns/orm-serialization-safety.md).

## Lo que se aplicó del framework

1. **Zero-Routing**: los módulos nuevos se registran en un registro central de módulos en vez de tocar el
   archivo de rutas — las colisiones de merge en el enrutador dejaron de repetirse. Ver
   [`zero-routing-frontend.md`](../docs/03_architecture_patterns/zero-routing-frontend.md).
2. **Layout Boundaries**: una regla única de contenedor flexible con altura mínima cero + prohibición de
   scroll global, para que cada módulo nuevo mantenga la misma consistencia visual sin que cada IA
   reinvente el contenedor. Ver
   [`strict-ui-layout-boundaries.md`](../docs/03_architecture_patterns/strict-ui-layout-boundaries.md).
3. **Scripts de despliegue, no comandos sueltos**: el flujo completo (parar procesos remotos colgados,
   reconstruir contenedores, reiniciar el proxy para invalidar su caché DNS, verificar healthchecks) se
   encapsuló en scripts versionados en vez de dictarle a cada sesión nueva la secuencia de comandos de
   memoria — reduce tanto el token gastado en reconstruir el procedimiento como el margen de error de
   saltarse un paso. Ver
   [`why-scripts-not-instructions.md`](../docs/00_philosophy/why-scripts-not-instructions.md).

## Un incidente adicional, fuera de lo anticipado

El servidor de staging era **compartido con contenedores de otro proyecto** en el mismo host. Más de una
vez, los contenedores de esta aplicación reportaban `Up (healthy)` pero la aplicación no respondía desde
afuera — la causa no era un bug propio sino un conflicto de puerto con el contenedor vecino. El diagnóstico
rápido (sospechar primero del vecino compartido en un host no dedicado) terminó siendo más valioso que
cualquier debugging del código de la aplicación misma.

**Regla generalizable**: en un host compartido con otros proyectos o equipos, ante un síntoma de "está
corriendo pero no responde", verificar conflictos de recursos (puertos, memoria) con el vecino **antes** de
asumir un bug propio.

## Conclusión

Ninguno de estos problemas se resolvió por un prompt mejor escrito — se resolvieron estructurando el código
y el flujo de trabajo para que la opción fácil (la que un LLM apurado toma por defecto) fuera también la
correcta. El retorno concreto y verificable no es un porcentaje de aceleración — es que los cuatro tipos de
incidente listados arriba dejaron de repetirse una vez que el patrón correspondiente quedó documentado y,
donde fue posible, encapsulado en un script.
