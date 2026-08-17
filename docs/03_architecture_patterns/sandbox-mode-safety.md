# Patrón: un modo sandbox solo está probado si se probó contra un sistema real

Cómo diseñar (y verificar) un modo de pruebas que aísla el proyecto de efectos reales — sin la falsa
seguridad de "funciona en sandbox" que solo se sostiene porque nunca se probó contra un cliente/registro
real de verdad.

## El problema

Un "modo sandbox" (o "modo de pruebas", "dry run", como se llame en el proyecto) casi siempre se
construye y se prueba contra datos ficticios: un cliente que no existe en la base real, un registro
inventado. Eso prueba que el código *funciona*, pero no prueba que el sandbox *aísla* — porque el camino
que se ejecuta cuando el registro no se encuentra suele ser distinto del camino que se ejecuta cuando sí
se encuentra. Si el sandbox solo intercepta el primer camino, cualquier prueba futura que sí encuentre un
registro real (por ejemplo, al conectar contra una base de producción de solo lectura para hacer una
prueba "más real") va a ejecutar el camino real sin ninguna de las protecciones del sandbox — y nadie lo
va a notar hasta que un efecto real (un archivo movido a una ruta real, un correo enviado a un contacto
real) ya ocurrió.

## El patrón: cada side-effect se intercepta por separado, e incondicionalmente

Un sistema con modo sandbox normalmente tiene más de un punto de side-effect real: dónde se escribe/mueve
un archivo, a quién se le envía una notificación, qué API externa se llama. **Cada uno es una superficie
de fuga independiente** — proteger uno no protege los demás, y "el sandbox ya está probado" después de
verificar solo uno es una conclusión falsa.

**Regla práctica:**
1. Listar explícitamente cada side-effect real del sistema (uno por uno, no como categoría genérica
   "efectos externos").
2. Para cada uno, la condición de sandbox debe ser: *"¿el modo sandbox está activo?"* — nunca
   *"¿el registro/cliente real se encontró?"*. Estas dos condiciones parecen equivalentes cuando se
   construye el sandbox con datos ficticios (donde el registro nunca se encuentra), pero dejan de serlo en
   el momento en que alguien prueba con acceso real — y son exactamente esas pruebas las que más
   necesitan la protección, porque son las que más se acercan a producción.
3. La prueba de que el sandbox funciona no es "corre sin errores con datos falsos" — es **conectar
   deliberadamente contra una fuente real de solo lectura y confirmar que ningún side-effect real
   ocurrió**, aunque el sistema sí haya encontrado y usado datos reales para todo lo demás (rutear,
   decidir nombres, etc.).
4. Cuando un side-effect redirige (ej. un correo que se manda a una dirección de prueba en vez de la
   real), mostrar en el propio resultado del side-effect redirigido cuál habría sido el destino real —
   así la prueba sigue siendo útil para validar la lógica real sin ejecutar el efecto real.

## Ejemplo real (caso C)

Un motor de validación de archivos por lotes tenía un `SandboxMode` que, al no encontrarse el cliente en
la base de datos (el caso normal en pruebas con datos falsos), usaba correctamente una carpeta y un
correo de prueba locales. Al conectar deliberadamente contra la base de datos de producción real (de solo
lectura) para probar con un cliente real como parte de una batería de pruebas "más realista", aparecieron
dos fugas distintas que las pruebas anteriores nunca habían expuesto:

- La carpeta destino de los archivos válidos se resolvía a la ruta real de red del cliente
  (`\\servidor\...\ClienteReal\...`) en vez de una carpeta local, porque el override de carpeta local del
  sandbox solo se aplicaba cuando estaba configurado explícitamente — y nunca lo había estado, porque
  nunca antes se había encontrado un cliente real para necesitarlo.
- El correo de resumen de errores se armaba con la condición *"si se encontró el cliente y tiene
  contactos reales, usar esos; si no, usar el correo de prueba"* — es decir, la condición evaluaba el
  registro encontrado, no el modo sandbox. Con un cliente real encontrado, el sistema estaba a punto de
  enviar el correo a los contactos reales del cliente, con `SandboxMode` activo y sin ninguna advertencia.

La corrección fue exactamente la regla 2: cambiar la condición de "¿se encontró el cliente?" a "¿está
activo el modo sandbox?" para el correo (con un addendum en el cuerpo mostrando los contactos reales que
se habrían usado, para no perder la utilidad de la prueba), y agregar el override de carpeta local
explícito para la ruta de destino. Ninguna de las dos fugas se habría encontrado sin probar
deliberadamente contra el sistema real — las pruebas contra datos falsos, por más que pasaran, nunca
iban a ejercitar el camino donde el registro sí se encuentra.

## Checklist corto

- [ ] ¿Está listado, explícitamente, cada side-effect real del sistema (no como categoría genérica)?
- [ ] ¿La condición de cada uno es "¿sandbox activo?" y no "¿se encontró/resolvió el dato real?"?
- [ ] ¿Se probó el sandbox conectando contra una fuente real de solo lectura, no solo contra datos
      ficticios?
- [ ] Si un side-effect se redirige, ¿el resultado muestra cuál habría sido el destino real?
