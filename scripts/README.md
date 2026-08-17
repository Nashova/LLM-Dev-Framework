# Scripts Operativos Universales

Colección de herramientas automatizadas (PowerShell `.ps1` para Windows y Bash `.sh` para Linux/macOS/WSL) diseñadas para diagnosticar, validar, conectar y desplegar proyectos con asistencia de IA.

## Catálogo de Scripts

| Script | Propósito | Cuándo se usa |
|---|---|---|
| `get-project-map.ps1` / `.sh` | Genera un mapa mental instantáneo del proyecto: ramas activas, archivos sin commitear, últimos commits, métricas por stack y puertos Docker. | **Al inicio de cada sesión** con el LLM o al cambiar de contexto. |
| `validate-knowledge-base.ps1` / `.sh` | Valida que el **archivo** de cada cita tipo `archivo:línea` en la documentación exista en el código activo (incluso en ramas no promovidas). No verifica que el número de línea siga siendo el correcto — eso requeriría anclar contenido, no solo rutas. | **Antes de cualquier PR o release**, para evitar documentación que miente. |
| `bootstrap-ai.ps1` / `.sh` | Genera o sincroniza los puntos de entrada para Claude (`CLAUDE.md`), Antigravity/Gemini (`GEMINI.md`), la convención multi-agente (`AGENTS.md`), Cursor (`.cursorrules`), Windsurf (`.windsurfrules`) y Copilot (`.github/copilot-instructions.md`). Nunca sobrescribe un archivo que no haya generado él mismo sin `-Force`/`--force`. | **Al iniciar el proyecto** o al modificar `AGENT_GUIDE.md`. |
| `sanitize-encoding.ps1` / `.sh` | Elimina de archivos ya UTF-8 los caracteres de control no compatibles con XML (`\x00`-`\x08`, `\x0B`-`\x0C`, `\x0E`-`\x1F`) y los reescribe sin BOM. Omite (nunca reescribe) cualquier archivo que no sea UTF-8 válido. Soporta `-DryRun`/`--dry-run`. | Cuando se detecta mojibake o errores de conversión en pipelines documentales. |
| `safety-check.ps1` / `.sh` | Chequeo de sintaxis, line-endings LF en scripts shell y alerta de "archivos de alto riesgo modificados sin actualizar doc viva". | En local antes de commitear. |
| `ship.ps1` / `.sh` | Pipeline automatizado: safety-check -> commit -> deploy opcional -> push -> creación/actualización de PR vía API REST (GitHub / Azure DevOps / GitLab). | Para entregar cambios formalmente. |
| `git-provider-pr.ps1` / `.sh` | Cliente REST desacoplado de CLIs externos para interactuar con proveedores Git sin fallar bajo firewalls corporativos. | Invocado internamente por `ship`. |

## Dependencias

- **PowerShell 5.1+** para los `.ps1`; **Bash 4+** para los `.sh`. Cada script existe en ambos sabores.
- `git` en el `PATH` (todos).
- Los `.sh` que hablan con APIs de git (`git-provider-pr.sh`, y `ship.sh` por transitividad) requieren
  además **`curl`** y **`python3`** — `python3` se usa para parsear JSON sin depender de `jq`.
  `sanitize-encoding.sh` también requiere `python3`.
- `gh` CLI es **opcional**: si no está, `git-provider-pr` usa la API REST directamente.

Los tokens **nunca** se pasan como argumento de `curl` (serían visibles en `ps` para cualquier usuario
del host); viajan por stdin vía `curl --config -`. Ver `git-provider-pr.sh`.

## Cómo adaptar a un proyecto nuevo

1. Copia `_config.template.ps1` (o `.sh`) como `_config.ps1`/`_config.sh` y ajusta las variables básicas (archivos riesgosos, docs vivas, y `ADO_*` si usas Azure DevOps). Ese archivo **sí se commitea** en tu proyecto: no contiene secretos.
2. Crea el archivo de secretos gitignored que documenta [`secrets-management.md`](../docs/03_architecture_patterns/secrets-management.md) — solo si vas a usar `ship` con creación automática de PR.
3. Ejecuta `bootstrap-ai.ps1` (o `.sh`) para sincronizar las reglas en todas las herramientas de IA que tu equipo use.
4. Ejecuta `get-project-map.ps1` para verificar el estado de partida.
5. Ejecuta `safety-check.ps1` para confirmar que los chequeos pasan en verde antes de tu primer commit.
