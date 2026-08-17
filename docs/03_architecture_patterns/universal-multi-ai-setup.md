# Patrón: configuración multi-IA generada desde una única fuente

Aplica a cualquier equipo donde más de una herramienta de IA (Claude Code, Cursor, Gemini, Copilot, Windsurf) trabaja sobre el mismo repositorio.

## El problema

Cada herramienta lee su propio archivo de reglas por convención:

| Herramienta | Archivo que lee |
|---|---|
| Claude Code | `CLAUDE.md` |
| Gemini CLI / Antigravity | (generado) `GEMINI.md` o `.agents/AGENTS.md` |
| Cursor | `.cursorrules` |
| Windsurf | `.windsurfrules` |
| GitHub Copilot | (generado) `.github/copilot-instructions.md` |

Mantener varios de estos archivos a mano lleva, tarde o temprano, a que se desincronicen — una regla se actualiza en `CLAUDE.md` pero no en `.cursorrules`, y la IA que use Cursor sigue operando con la regla vieja sin que nadie lo note hasta que causa un error.

## El patrón: `AGENT_GUIDE.md` como fuente única, con dos formas de propagarla

`AGENT_GUIDE.md` (ver la raíz de este framework) es siempre la fuente que se edita. De ahí a los archivos que cada herramienta espera hay dos caminos válidos, según lo que la herramienta y el sistema operativo permitan:

1. **Symlink** (preferido cuando es viable): cada archivo específico de herramienta es un enlace simbólico a `AGENT_GUIDE.md` — cero riesgo de desincronización, porque no hay una copia real que actualizar. Limitación real: crear symlinks en Windows sin modo desarrollador/permisos elevados no siempre es viable, y algunas herramientas no siguen bien un symlink.
2. **Generación de copias físicas** (`scripts/bootstrap-ai.ps1`/`.sh`): cuando el symlink no es viable, el script lee `AGENT_GUIDE.md` y escribe una copia literal en cada archivo que cada herramienta espera (generado: `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.windsurfrules`, `AGENTS.md`, `.github/copilot-instructions.md`), con un encabezado de advertencia (`ARCHIVO AUTOGENERADO — NO EDITAR DIRECTAMENTE`) para que nadie edite la copia por error. Correr el script de nuevo tras cada cambio a `AGENT_GUIDE.md` sincroniza todas las copias a la vez.

## Regla práctica

- `AGENT_GUIDE.md` se edita siempre; los demás archivos nunca se editan directamente — ni a mano, ni por una IA que no se dio cuenta de que eran una copia generada.
- Si el equipo usa más de una herramienta de IA, correr `bootstrap-ai.ps1`/`.sh` (o crear los symlinks) como parte del bootstrap del proyecto, no como una idea posterior — ver el paso correspondiente en [`new-project-checklist.md`](../01_bootstrap/new-project-checklist.md).
- Volver a correr el script cada vez que `AGENT_GUIDE.md` cambie de forma sustancial — un archivo espejo desactualizado es, en la práctica, tan malo como no haber tenido nunca esta convención.

## Checklist corto

- [ ] ¿Existe exactamente un archivo que se edita a mano (`AGENT_GUIDE.md`), y el resto son symlinks o copias autogeneradas?
- [ ] ¿Las copias generadas tienen un encabezado de advertencia que impida editarlas por error?
- [ ] ¿El script de generación se corrió después del último cambio sustancial a `AGENT_GUIDE.md`?
