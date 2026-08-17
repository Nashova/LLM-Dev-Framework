# Patrón: RBAC en cascada + funciones granulares con fallback seguro

Patrón de control de acceso probado en producción (caso A, tras cuatro fases de rediseño real). Es una referencia de diseño — la jerarquía de entidades de cuatro niveles del ejemplo es la que encajó con una organización concreta; el patrón subyacente (jerarquía + cascada de alcance + funciones granulares con fallback seguro) es lo reusable, no los nombres de las entidades.

## El problema que resuelve

Un modelo de permisos plano ("cada usuario tiene una lista de roles") funciona bien al principio y se vuelve inmanejable cuando aparece la primera excepción real: *"este usuario debería poder editar X pero no Y, aunque ambos son del mismo rol"*. La reacción típica es agregar un flag booleano ad-hoc por excepción — y cada flag nuevo es una combinación más que nadie termina de entender ni de testear.

## El patrón: tres capas independientes que se combinan

### Capa 1 — Rol jerárquico numérico

Cada usuario tiene EXACTAMENTE un rol, y cada rol tiene un nivel numérico (`level`) en vez de compararse por nombre (`role == "Admin"`). Dejar huecos entre niveles (10, 20, 30, no 1, 2, 3) para poder insertar un rol intermedio después sin renumerar todo.

```
Administrador = 30
Operator      = 20
Lector        = 10
```

Comparar SIEMPRE por nivel (`user.role.level >= required_level`), nunca por nombre — el nombre de un rol puede cambiar (pasó en un caso real: un rol se renombró a mitad de proyecto) y cualquier comparación por string hardcodeado se rompe silenciosamente en ese momento.

### Capa 2 — Cascada de alcance

Si el sistema tiene una jerarquía de "dónde" puede operar un usuario (áreas de negocio → aplicaciones → módulos, o el equivalente que aplique), cada nivel de la cascada exige que el nivel padre YA esté entre los del usuario para poder asignarle el nivel hijo. Esto evita el estado inconsistente de "tiene acceso a un módulo de una aplicación que no tiene asignada".

**Invariante a mantener siempre:** un nodo hijo nunca puede ser más permisivo que su padre en la cascada (ej. un módulo no puede requerir un rol menor al que ya exige su sección padre). Validar esto en el punto de escritura (al asignar/crear), no confiar en que nadie va a crear una inconsistencia — alguien lo va a hacer, por accidente, tarde o temprano.

**El usuario superadministrador (si existe) bypassea la cascada, NUNCA las invariantes de coherencia del objetivo.** Distinción importante: un superadmin puede asignar cualquier cosa a cualquiera (bypassa el chequeo de "¿tengo yo mismo este alcance?"), pero el objeto resultante todavía tiene que ser coherente (un usuario Lector no puede terminar con un módulo que exige nivel Administrador, ni siquiera si fue el superadmin quien lo asignó por error). Mezclar estos dos bypasses es una fuente real de bugs de seguridad sutiles.

### Capa 3 — Funciones granulares con fallback seguro

Un nivel MÁS FINO que el módulo/pantalla completa: gatear una acción PUNTUAL dentro de un módulo ya accesible. Ejemplo: "ver el dashboard" requiere Lector, pero "agregar una app al dashboard" (una acción específica dentro de ese mismo módulo) requiere Administrador.

**La regla de oro de esta capa:** si el código de una función granular no está configurado en la base de datos/config (todavía no se sembró, alguien lo borró por error, lo que sea), el sistema **cae a "solo administrador"**, nunca a "cualquiera puede". Un hueco de seguridad silencioso (una función sin configurar que termina siendo accesible para todos) es mucho peor que una función sobre-restringida temporalmente — lo segundo se nota de inmediato (alguien reporta "no puedo hacer X"), lo primero no se nota hasta que alguien lo explota o audita.

```
si code no existe en la config:
    devolver "requiere administrador"   # nunca "permitir a cualquiera"
si code existe:
    comparar nivel del usuario contra el nivel minimo configurado para code
```

## Por qué tres capas separadas y no una sola tabla de permisos gigante

Cada capa cambia a un ritmo distinto. El rol jerárquico casi no cambia una vez definido. La cascada de alcance crece cuando el negocio agrega una unidad organizacional nueva. Las funciones granulares se agregan constantemente, una por una, a medida que aparece una necesidad puntual de "esto necesita más/menos restricción que el módulo completo". Separarlas en capas independientes significa que agregar una función granular nueva no toca nada de las otras dos capas — en un modelo de permisos monolítico, cada cambio pequeño arriesga romper algo no relacionado.

## Trampas comunes a evitar

- **Comparar roles por nombre en vez de por nivel numérico** — se rompe en el primer rename.
- **Dejar que una función granular sin configurar sea accesible por default** — hueco de seguridad silencioso.
- **No separar "el actor puede hacer esto" de "el objetivo resultante es coherente"** — el bypass de un superadmin sobre lo primero no debería nunca aplicar a lo segundo.
- **Endpoints de listado/lectura con el mismo gate que los de escritura** — un usuario sin permiso de gestionar usuarios normalmente sí necesita poder ver catálogos de solo-lectura (roles disponibles, opciones de un selector) para que la UI funcione; gatear eso igual de estricto que la escritura genera bugs de UI confusos ("no puedo ni ver las opciones del dropdown").
