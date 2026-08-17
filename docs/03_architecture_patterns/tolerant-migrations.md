# Patrón: migraciones tolerantes en ambientes greenfield y legacy a la vez

Aplica a cualquier herramienta de migración de schema (Alembic, Prisma Migrate, Django migrations, Flyway, Rails migrations) cuando el mismo código de migración va a correr tanto contra una base de datos nueva (sin datos previos) como contra una que ya tiene historia real.

## El problema

Una migración que asume "esta columna/tabla no existe todavía" falla en un ambiente donde SÍ existe (alguien ya la agregó a mano, o una migración anterior ya la creó en un ambiente pero no en otro por un despliegue parcial). Una migración que asume "el dato de referencia que necesito ya existe" (un rol, una categoría, un flag de configuración) falla en un ambiente completamente nuevo donde ese seed todavía no corrió.

## El patrón: verificar antes de actuar, nunca asumir

**Para cambios de schema** (agregar columna/tabla/índice): verificar programáticamente si el elemento ya existe antes de intentar crearlo. Si ya existe, saltar ese paso sin error — la migración es idempotente. Esto es más importante de lo que parece en bases de datos que no soportan bien `ALTER TABLE` estructural sin recrear la tabla (SQLite es el caso clásico) — ahí, además, hay que usar el modo de "recreación por lotes" que ofrezca la herramienta en vez de intentar el ALTER directo.

```
si "columna_nueva" no está en las columnas actuales de "tabla":
    agregar la columna
si no:
    seguir sin error
```

**Para datos semilla que la migración necesita referenciar** (ej. "asignar esta función granular nueva al rol Administrador" — necesita que el rol "Administrador" ya exista): buscar el dato de referencia primero; si no existe, hacer un **backfill tolerante** — loggear un aviso claro y seguir sin fallar, en vez de abortar toda la migración. El seed faltante se resuelve solo, sin intervención manual, la próxima vez que corra la cadena completa de migraciones DESPUÉS de que el prerequisito exista (útil cuando el prerequisito se crea en runtime por otra vía, ej. una UI de administración, no por una migración de schema).

```
buscar "modulo_x" en la tabla de módulos
si no existe:
    loggear "omitiendo seed de función Y: módulo X no encontrado en esta DB -- se resuelve en un upgrade posterior"
    seguir sin fallar
si existe:
    insertar el seed
```

## Nombrar los constraints explícitamente

Al agregar foreign keys o constraints en una migración, nombrarlos explícitamente (`fk_tabla_columna_tabla_referenciada`) en vez de dejar que la base de datos autogenere el nombre. Algunas bases de datos (SQLite en particular) necesitan el nombre explícito para poder referenciar ese constraint en una migración FUTURA que quiera modificarlo — sin el nombre, esa migración futura no tiene forma limpia de identificar qué constraint tocar.

## Nunca usar el "sync automático" del ORM en producción

Cualquier mecanismo de "crear las tablas automáticamente a partir de los modelos" (`create_all()`, `sync()`, `db push` sin generar un archivo de migración) genera **drift silencioso**: el schema real de la base de datos y lo que las migraciones formales creen que existe se desincronizan sin que nadie lo note, hasta que una migración futura falla de una forma confusa porque asume un estado que no es el real. Las migraciones formales (archivos versionados, aplicados en orden, con historial) son la ÚNICA fuente de verdad del schema — el sync automático es aceptable únicamente en desarrollo local descartable, nunca en un ambiente que alguien más va a tocar después.

## Verificar el backfill contra un schema histórico real, no contra el actual

Al escribir una migración de backfill (poblar una columna nueva con datos derivados de columnas existentes), verificarla corriendo la cadena de migraciones desde cero puede ser engañoso si el "baseline" inicial del proyecto ya refleja el modelo ACTUAL (con la columna nueva ya declarada) en vez del estado histórico real que existía cuando la migración de backfill se va a aplicar en un ambiente real ya desplegado. Si esto aplica, construir una base de datos de prueba con una versión ANTERIOR real de los modelos (sin la columna nueva) antes de aplicar la migración de backfill — sólo así se prueba el camino que realmente va a correr en producción.
