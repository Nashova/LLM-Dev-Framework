# Caso D: el framework auditándose a sí mismo antes de publicarse

Este caso es distinto de los otros tres: no viene de un sistema externo, sino de **este repositorio**. El
2026-08-17, el framework pasó de repo privado a repo público en GitHub, y antes de eso se auditó con sus
propias reglas. El resultado es la mejor prueba de la tesis del framework y también su crítica más honesta:
**un catálogo de patrones no protege a quien lo escribió de cometer los errores que documenta.**

Se conserva como caso de estudio porque el procedimiento es reusable —está destilado en la skill
[`pre-publication-audit`](../skills/pre-publication-audit/SKILL.md)— y porque los hallazgos son un mapa de
qué tipo de defecto se acumula en un repo de documentación y scripts.

## El método

Siete auditores independientes en paralelo, cada uno con una lente distinta y ciego a lo que veían los
demás: confidencialidad de cliente, seguridad de los scripts PowerShell, seguridad de los Bash y paridad
entre gemelos, completitud estructural, integridad de referencias cruzadas, higiene de encoding, y
usabilidad para un desconocido. Cada hallazgo pasaba después por un verificador adversarial cuyo trabajo
era **refutarlo**, con instrucción explícita de descartar el falso positivo más común: confundir un
`<!-- TODO -->` deliberado de una plantilla con un descuido del autor.

### Lo que salió mal del método, y qué se aprendió

Dos cosas, y ambas son la lección más transferible de este caso:

1. **La corrida se topó con el límite de sesión.** Completaron 5 de 7 auditores y murieron 65 de 75
   agentes. Peor: el código de agregación contaba como "confirmado" todo hallazgo cuyo verificador no
   había devuelto un veredicto explícito, así que reportó "77 confirmados" cuando en realidad **75 no se
   habían verificado**. Un pipeline que trata la ausencia de refutación como confirmación produce un
   número que parece riguroso y no lo es. La regla: **distinguir "verificado y aprobado" de "no
   verificado" en la estructura de datos, nunca colapsarlos en un booleano.**

2. **Los auditores leyeron una versión distinta de la que estaba en disco.** Se los apuntó a una ruta que
   resolvía al estado *commiteado*, mientras el working tree tenía correcciones sin commitear. Resultado:
   3 hallazgos describían defectos ya resueltos —incluido el más llamativo, que el validador de citas del
   framework fallara contra su propia documentación (pasa limpio: 31 citas, 0 rotas)—. Se detectó porque
   antes de "arreglar" cada hallazgo se verificó contra el disco. La regla: **verificar cada hallazgo
   heredado contra el estado real antes de actuar sobre él**, que es exactamente
   [`verify-before-claiming`](../skills/verify-before-claiming/SKILL.md) aplicada a un informe de auditoría.

## Los hallazgos, por clase

### Confidencialidad: el problema no eran los nombres

Lo esperado era encontrar nombres de sistemas de cliente. Lo que se encontró fue bastante más:

| Lo que se buscaba | Lo que además apareció |
|---|---|
| Nombres de sistemas | El **sector** del negocio, que combinado con el stack identifica a la empresa |
| — | Versiones exactas de framework (huella digital) |
| — | Nombres de contenedores, y que dos clientes distintos compartían host de staging |
| — | Nombres de **columnas internas** de base de datos |
| — | **Detalle operativo explotable**: un gap de configuración de producción sin remediar, una tarea destructiva apuntando a datos reales de un tercero, credenciales de identidad horneadas en un artefacto de build |

La última fila es la que importa. Documentar un incidente resuelto es valioso; publicar **la
vulnerabilidad vigente de un sistema real** es otra cosa. Ese fue el criterio de corte: se conservó el
mecanismo de cada incidente y su regla, se eliminó todo lo que permitiera identificar al sistema o
explotarlo.

Y no estaban donde uno mira: las ~30 referencias repartidas en encabezados de scripts, `.gitattributes`,
nombres de archivo y notas de procedencia costaron más trabajo que los tres archivos obvios.

### Seguridad: la herramienta que destruía configuración ajena

El hallazgo más grave no era una fuga, era un script. `bootstrap-ai` —diseñado explícitamente para
correrse en proyectos de otros— sobrescribía `CLAUDE.md`, `.cursorrules`, `GEMINI.md` y compañía **sin
avisar ni respaldar**. Cualquiera con un `CLAUDE.md` escrito a mano lo perdía en la primera corrida.

Los otros tres, en orden de gravedad:

- El PAT viajaba como **argumento de `curl`**, visible en `ps` para cualquier usuario del host. Se pasó a
  stdin vía `curl --config -`.
- `sanitize-encoding` decodificaba como UTF-8 **sin validar**: un archivo Latin-1 quedaba permanentemente
  corrompido con `U+FFFD`. La herramienta de higiene de encoding destruía archivos por un problema de
  encoding.
- Una respuesta de **error** de la API de GitHub se interpretaba como "el PR ya existe", y el pipeline
  terminaba en éxito sin haber creado nada. Con Bitbucket devolvía `0` directamente.

El patrón común: **los cuatro fallan en silencio o reportando éxito.** Ninguno tira un error. Es la clase
de defecto que sobrevive años porque nada lo señala.

### Veracidad: el framework incumpliendo su propia regla

El framework predica que "la documentación jamás debe mentir sobre el código". El suyo mentía en varios
lugares: prometía un `sanitize-encoding.sh` que no existía, contaba 14 patrones cuando había 23, citaba
una sección `§2` que trataba de otro tema, y atribuía a un README una estructura de carpetas que ese
README no definía.

Dos hallazgos estructurales de fondo, más interesantes que los conteos:

- **Tres convenciones de carpeta de documentación conviviendo** sin que ninguna fuera la oficial. Se
  resolvió declarando la canónica en el README de plantillas —lo que además volvió *ciertas* las dos
  atribuciones que antes eran falsas.
- **Patrones exclusivos de SPA presentados como reglas universales.** Un proyecto CLI o backend recibía
  como obligatorias tres reglas de frontend. Un checklist con ítems irrelevantes se deja de leer completo,
  así que el daño no era el ítem sobrante: era la pérdida de credibilidad del checklist entero.

### El bug que ningún auditor encontró

Apareció después, escribiendo código nuevo: un guion largo `—` dentro de un string de un `.ps1` rompía el
parseo entero del script. PowerShell 5.1 lee `.ps1` sin BOM como CP1252, donde el último byte del guion
largo es `U+201D` —una comilla que PowerShell **acepta como delimitador de cadena**—. El string terminaba
antes de tiempo y el parser tiraba una cascada de errores señalando líneas correctas.

Lo encontró **ejecutar el script**, no leerlo. Está documentado en
[`encoding-and-text-hygiene.md`](../docs/03_architecture_patterns/encoding-and-text-hygiene.md) porque la
lección generaliza: **un problema de encoding puede presentarse como un error de sintaxis**, y quien busque
el bug en la lógica no lo encuentra nunca.

Mismo origen tuvo otro bug propio: un `grep -c "$patron" || echo 0` que imprimía **dos** ceros —`grep -c`
ya imprime `0` cuando no hay match, y además sale con código 1— rompiendo toda comparación aritmética
posterior. También apareció al ejecutar, no al revisar.

### El error más elocuente: la skill anti-fuga que filtró datos

Al escribir la skill [`pre-publication-audit`](../skills/pre-publication-audit/SKILL.md), su tabla de
"qué anonimizar" se ilustró con los **datos reales del cliente**: el stack con versiones exactas, el
sector del negocio y la topología de repos, textuales, como columna de ejemplos. Es decir: la skill cuyo
propósito es evitar filtrar la huella digital de un cliente **la reintrodujo en un repo público**, tres
commits después de haberla eliminado.

Lo detectó el barrido de la Fase 5 —clonar el remoto y buscar sobre el clon— y obligó a una segunda
reescritura del historial. La corrección fue reescribir la tabla para describir **clases** de dato
("stack con versiones exactas") en vez de instancias.

Dos lecciones, y la segunda es la que vale:

1. **No uses datos reales como ejemplo de qué ocultar.** Un ejemplo ilustrativo se publica igual que
   cualquier otro texto.
2. **La verificación desde afuera no es opcional ni ceremonial.** Si el barrido sobre el clon se hubiera
   dado por hecho —"ya limpiamos todo, el push salió bien"— la fuga habría quedado publicada
   indefinidamente. Ese paso encontró lo que siete auditores, un verificador adversarial y quien escribió
   la corrección no vieron.

## La decisión que no era técnica

Anonimizar los archivos **no borra nada del historial**. Los nombres seguían en los tres commits ya
pusheados, recuperables con `git log -p`. Eso no lo resuelve un script: es una decisión del dueño, con tres
opciones de costo muy distinto (borrar y recrear el repo, reescribir el historial y forzar el push, o no
tocar el historial). Se presentaron las tres con su costo real —incluido que **tras un force-push GitHub
deja los commits viejos accesibles por su SHA directo**, posiblemente para siempre— y el dueño eligió
reescribir el historial. Se dejó un tag local de respaldo, con la advertencia explícita de no pushearlo
nunca.

La verificación final no fue "el push salió bien": fue **clonar el remoto en un directorio limpio** y
barrer el clon. Es la única comprobación que refleja lo que ve un tercero.

## Lo que este caso confirma

1. **Escribir el patrón no vacuna contra el error que describe.** El framework tenía un patrón de higiene
   de encoding y su propia guía maestra con dos bloques de texto corrompidos; un patrón de gestión de
   secretos y un `.gitignore` que impedía trackear la plantilla que ese patrón exige.
2. **Ejecutar encuentra lo que leer no encuentra.** Los dos bugs más difíciles de esta sesión aparecieron
   al correr los scripts. Ninguna cantidad de auditores leyendo los habría visto.
3. **Un informe de auditoría es una fuente heredada como cualquier otra.** Tres de sus hallazgos eran
   falsos contra el estado real. Verificar antes de actuar aplica también —sobre todo— cuando la fuente es
   un proceso que parece riguroso.
4. **Los defectos que reportan éxito son los que sobreviven.** Los cuatro problemas de seguridad
   encontrados fallaban en silencio. Vale más auditar buscando "qué cosa devuelve 0 sin haber hecho su
   trabajo" que buscando código feo.

## Relacionado

- [`pre-publication-audit`](../skills/pre-publication-audit/SKILL.md) — el procedimiento destilado y reusable.
- [`verify-before-claiming`](../skills/verify-before-claiming/SKILL.md) — la regla que atrapó los 3 hallazgos falsos.
- [`../CHANGELOG.md`](../CHANGELOG.md) — el detalle itemizado de cada corrección.
- [`encoding-and-text-hygiene.md`](../docs/03_architecture_patterns/encoding-and-text-hygiene.md) — el bug del guion largo.
