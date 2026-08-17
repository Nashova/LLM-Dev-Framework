# Patrón: secretos para scripts de automatización local

Cómo manejar credenciales (contraseñas de servidores, tokens de API, PATs de proveedores de git) que los scripts de automatización de un proyecto necesitan en runtime, sin que terminen expuestas en el historial de git.

## La regla de una sola línea

**Ningún archivo TRACKEADO en git contiene un secreto real, ni siquiera "temporalmente".** No hay excepción de "lo saco después" — una vez que un commit con un secreto se pushea a un remoto compartido, ese secreto queda expuesto para siempre en el historial, incluso si un commit posterior lo "corrige". Hallazgo real de uno de los proyectos que originaron este framework: un secreto se hardcodeó en un script "solo por ahora" y quedó expuesto en dos remotos de git distintos durante semanas hasta que alguien lo notó — corregirlo en el archivo actual no invalidó lo que ya estaba en el historial.

## El patrón de dos archivos

1. **Un archivo de configuración TRACKEADO** (ej. `_config.ps1`/`_config.sh`) con todo lo que NO es secreto — hosts, puertos, nombres de organización/proyecto, patrones de rutas — más funciones que **leen** los secretos reales desde el segundo archivo en tiempo de ejecución.
2. **Un archivo de secretos GITIGNORED** (template: `.local/secrets.json`, bajo un directorio explícitamente excluido en `.gitignore`) con los valores reales. Este archivo NUNCA se commitea — cada persona/máquina que necesita correr los scripts lo crea a mano, una vez, copiando el formato de un archivo `.template.json` que SÍ está trackeado (con valores de ejemplo, nunca reales).

```
_config.ps1 (trackeado)          .local/secrets.json (gitignored)
├─ $HOST = "..."                 ├─ { "secrets": {
├─ $PORT = "..."                 │      "staging_ssh_password": "...",
└─ function Get-Secret($name)    │      "azuredevops_pat": "..."
      lee .local/secrets.json ──►│   } }
```

La función `Get-Secret`/`get_project_secret` (ver `scripts/_config.template.ps1`/`.sh` del framework) debe **tirar un error explícito** si el archivo de secretos no existe o no tiene la clave pedida — nunca caer a un valor por default silencioso. Un error claro ("falta el archivo de secretos, crealo con este formato") es infinitamente más útil que un script que falla de forma confusa más adelante por una credencial vacía, o peor, que sigue funcionando con un valor por default inseguro.

## Por qué gitignored y no un gestor de secretos completo (Vault, AWS Secrets Manager, etc.)

Para secretos de AUTOMATIZACIÓN LOCAL de desarrollo (no secretos de la aplicación en producción, que sí merecen un gestor real), el costo de operar un gestor de secretos completo supera el beneficio en la mayoría de los proyectos — especialmente en la fase inicial. El patrón de archivo gitignored es suficiente mientras: (a) el número de personas que necesitan estos secretos es pequeño, (b) no hay un requisito de compliance que exija rotación automática o auditoría de acceso a nivel de infraestructura. Si el proyecto crece hasta necesitar eso, migrar a un gestor real es un cambio localizado (solo tocar la función `Get-Secret`, todo lo que la llama sigue igual) — no hace falta anticiparlo desde el día 1.

## Si el secreto YA quedó expuesto en el historial

Mover el secreto a la ubicación correcta de ahora en adelante NO invalida el valor que ya está en commits viejos. Dos caminos, con costos muy distintos:

- **Rotar el secreto** (cambiarlo en el sistema real que lo usa) — invalida instantáneamente lo que quedó expuesto en el historial, sin tocar el historial en sí. Es la opción recomendada casi siempre.
- **Reescribir el historial de git** (herramientas como `git filter-repo` o BFG Repo-Cleaner) para eliminar el secreto de todos los commits pasados — mucho más invasivo: rompe cualquier clon existente del repo, requiere forzar el push a todos los remotos, y hay que coordinarlo con cualquiera que tenga una copia local. Solo vale la pena si rotar el secreto no es una opción (ej. un identificador que no se puede cambiar).

## Addendum: probar contra un sistema real de solo lectura sin tocar ningún archivo trackeado

Cuando hace falta probar algo contra una credencial real (ej. una base de datos de producción con un
usuario de solo lectura) para una prueba puntual, sin que esa credencial quede escrita ni siquiera
temporalmente en un archivo de configuración trackeado — la forma correcta es un override de variable de
entorno para esa única ejecución, nunca editar el archivo de configuración tracker "solo por esta vez y
después lo revierto" (ese es exactamente el patrón que expone secretos en el historial de git, ver la
regla de una sola línea arriba). *Ejemplo real (caso C):* para validar un comportamiento contra la
base de datos real de producción (acceso de solo lectura), la credencial se pasó como variable de entorno
en el comando de la prueba puntual, siguiendo la misma convención de override por variable de entorno que
el proyecto ya usaba para configuración no-secreta — ningún archivo trackeado se tocó, y no quedó ningún
rastro que "revertir" después.

## Formato mínimo sugerido para el archivo de secretos

```json
{
  "_note": "LOCAL ONLY -- nunca commitear.",
  "secrets": {
    "staging_ssh_password": "...",
    "azuredevops_pat": "...",
    "github_token": "..."
  }
}
```

Un solo archivo con todos los secretos del proyecto es más fácil de mantener que uno por servicio — la protección real la da el `.gitignore`, no la cantidad de archivos.
