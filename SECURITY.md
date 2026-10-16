# Política de seguridad

## Cómo reportar una vulnerabilidad

Usa el **reporte privado de GitHub**: pestaña **Security → Report a vulnerability**, o directamente
<https://github.com/Nashova/LLM-Dev-Framework/security/advisories/new>.

No abras un issue público con detalles explotables. Es un proyecto personal sin plazo de respuesta garantizado; los reportes se atienden en cuanto es posible.

## Qué cuenta como vulnerabilidad

Este repositorio contiene documentación y scripts (PowerShell y Bash) que se ejecutan en la máquina de quien los usa y que manejan tokens de proveedores git (`ship`, `git-provider-pr`). Por eso interesan especialmente:

- Inyección de comandos o de argumentos a partir de entradas del usuario, ramas, mensajes de commit o respuestas de una API.
- Exposición de tokens o secretos (en argumentos de proceso, logs, archivos temporales o el historial de git).
- Escritura o borrado fuera del directorio de destino, o sobrescritura de archivos sin confirmación.
- Cualquier forma de que una skill o un script ejecute algo distinto de lo que documenta.

No se consideran vulnerabilidades las recomendaciones de endurecimiento sin un escenario de ataque concreto, ni los patrones de la documentación que no son código ejecutable (esos se discuten como issues normales).

## Versiones soportadas

Solo la rama `main`. El proyecto todavía no publica versiones etiquetadas.

## Cómo manejan los secretos los scripts

Los tokens **nunca** se pasan como argumento de `curl` (serían visibles en `ps` para cualquier usuario del host): viajan por la entrada estándar con `curl --config -`, y se leen en tiempo de ejecución desde un archivo local ignorado por git. Ver [`secrets-management.md`](docs/03_architecture_patterns/secrets-management.md) y [`scripts/README.md`](scripts/README.md).
