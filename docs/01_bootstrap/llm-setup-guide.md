# Guía de instalación por herramienta de IA

Cómo dejar este framework operativo en cada herramienta, desde las más capaces hasta un modelo local
corriendo en tu máquina.

> **Las rutas de configuración de estas herramientas cambian.** Este documento refleja lo que era válido
> cuando se escribió; el lugar canónico donde se mantienen es
> [`scripts/install-skills.ps1`](../../scripts/install-skills.ps1)/[`.sh`](../../scripts/install-skills.sh).
> Si una herramienta cambió su formato, arreglá el emisor en el instalador —no seis archivos a mano— y
> corré el script de nuevo. Ante una discrepancia entre este doc y la doc oficial de la herramienta, manda
> la oficial: reportalo en una línea (ver [`collaboration-style.md`](../00_philosophy/collaboration-style.md)).

## Los dos pasos comunes a todas

Sin importar la herramienta, el framework se instala igual:

```bash
FW=/ruta/donde/clonaste/LLM-Dev-Framework
cd /mi-proyecto

# 1. La guía de entrada: una sola fuente de verdad, copias generadas por herramienta
cp "$FW/AGENT_GUIDE.md" .
#    ...editá las secciones <!-- TODO --> con la realidad de tu proyecto...
bash "$FW/scripts/bootstrap-ai.sh"

# 2. Las skills, en el formato que tu herramienta espera
bash "$FW/scripts/install-skills.sh" --target . --tool <herramienta>
```

El paso 1 genera `CLAUDE.md`, `GEMINI.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules` y
`.github/copilot-instructions.md` (generado) — todos derivados del mismo `AGENT_GUIDE.md`, para que las reglas no se
desincronicen entre herramientas. El paso 2 agrega los protocolos que se auto-disparan.

Ambos scripts **respetan** cualquier archivo que ya tuvieras escrito a mano: avisan y no lo tocan.

---

## Herramientas con soporte nativo de skills

Acá el framework rinde al máximo: los protocolos se activan solos según la tarea.

### Claude Code

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool claude
```

Genera `.claude/skills/<nombre>/SKILL.md`. Se descubren automáticamente por su `description`; no hay que
registrarlas en ningún índice. Para tenerlas en **todos** tus proyectos, instalá en `~/.claude/skills/`
en vez del proyecto:

```bash
bash "$FW/scripts/install-skills.sh" --target "$HOME" --tool claude
```

Verificá con `/skills` en una sesión. La guía de entrada la lee de `CLAUDE.md`.

### Cursor

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool cursor
```

Genera `.cursor/rules/<nombre>.mdc` con `alwaysApply: false`, así que el modelo decide cuándo cargar cada
regla según su `description` — que es el comportamiento que queremos: nueve reglas siempre activas
consumirían contexto sin aportar.

Cursor lee además `.cursorrules` (generado por `bootstrap-ai`) como reglas de proyecto.

### GitHub Copilot

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool copilot
```

Genera `.github/instructions/<nombre>.instructions.md` con `applyTo: '**'`. Copilot los aplica según el
archivo en que estés trabajando; si querés acotar una skill a cierto tipo de archivo, editá su `applyTo`
después de generarla (ej. `applyTo: '**/*.sql'` para las de migraciones).

`bootstrap-ai` genera además (generado) `.github/copilot-instructions.md`, que Copilot lee para todo el repo.

### Windsurf

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool windsurf
```

Genera `.windsurf/rules/<nombre>.md` con `trigger: model_decision`, el equivalente a la activación por
descripción.

---

## Herramientas de un solo archivo de contexto

No tienen carpeta de skills, así que el instalador concatena todo en **un playbook con tabla de ruteo** al
principio: el modelo lee la tabla, identifica si su tarea encaja en una fila, y sólo entonces lee esa
sección.

### Gemini CLI / Code Assist

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool gemini
```

Genera (generado) `.gemini/skills-playbook.md`. **Falta un paso manual**: agregá a tu `GEMINI.md` la línea

```
@.gemini/skills-playbook.md
```

Gemini CLI resuelve esos imports al cargar el contexto. Sin esa línea, el playbook existe pero nadie lo lee.

### Codex CLI y cualquier herramienta que use `AGENTS.md`

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool codex
```

Genera `.agent-skills-playbook.md`. Referencialo desde el `AGENTS.md` que produjo `bootstrap-ai`, o pegá su
contenido al final si la herramienta no resuelve imports.

### ChatGPT (web) y GPTs personalizados

No hay instalación por archivos; el vehículo es el contexto del proyecto:

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool generic
```

1. Creá un **Project** en ChatGPT.
2. Subí como archivos de conocimiento: `AGENT_GUIDE.md`, `LLM_PLAYBOOK.md`, y tus
   `architecture.md` + `change-safety.md`.
3. En las instrucciones del proyecto, pegá:

   > Antes de responder cualquier pedido técnico sobre este repositorio, consultá la tabla de ruteo de
   > `LLM_PLAYBOOK.md`. Si la tarea encaja en una fila, leé esa sección completa antes de actuar. No
   > afirmes que un archivo o función existe sin que yo te lo haya mostrado en esta conversación.

La última frase importa más de lo que parece: sin acceso al filesystem, el modelo **no puede** verificar
nada, así que la regla de `verify-before-claiming` se vuelve "no afirmes, preguntá".

---

## Modelos locales

Un modelo local no es un modelo grande lento: falla en cosas distintas. Antes de configurarlo, leé
[`working-with-small-models.md`](../00_philosophy/working-with-small-models.md) — define qué esperar de
cada tamaño y qué tareas no delegarle nunca.

### Continue.dev (VS Code / JetBrains, con Ollama o LM Studio detrás)

Es la mejor opción para modelos locales, porque **sí** tiene activación por descripción:

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool continue
```

Genera `.continue/rules/<nombre>.md`. Con un modelo local de 14B o más, la activación por descripción
funciona de forma aceptable. Por debajo de eso, conviene el playbook manual.

### Ollama / LM Studio directo

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool generic --skills small-model-handoff,safe-change-gate,verify-before-claiming
```

**Instalá pocas skills, no las nueve.** El playbook completo son miles de tokens y un modelo chico se pierde
en ellos; ese contexto compite con la tarea real.

Con Ollama, fijá el system prompt en un `Modelfile`:

```
FROM qwen2.5-coder:14b
PARAMETER num_ctx 16384
SYSTEM """
Sos un asistente de desarrollo en este repositorio. Reglas:
1. Un paso por respuesta. No planifiques varios pasos.
2. No modifiques ningún archivo que no se te haya nombrado explícitamente.
3. Si algo no está claro, respondé "NECESITO ACLARACION: <qué>" y detenete. No adivines.
4. No afirmes que un archivo, función o columna existe si no la viste en el contexto.
"""
```

```bash
ollama create mi-asistente -f Modelfile
```

`num_ctx` es el parámetro que más se olvida: el default de Ollama suele ser mucho menor que la ventana
real del modelo, y el resultado es que el modelo "olvida" tus instrucciones a mitad de la tarea sin
ninguna señal de error.

### aider

```bash
bash "$FW/scripts/install-skills.sh" --target . --tool generic
aider --read LLM_PLAYBOOK.md --read AGENT_GUIDE.md
```

---

## Tabla resumen

| Herramienta | `--tool` | Activación | Nota |
|---|---|---|---|
| Claude Code | `claude` | Automática | También global en `~/.claude/skills/` |
| Cursor | `cursor` | Automática | `alwaysApply: false` a propósito |
| GitHub Copilot | `copilot` | Automática | Acotá `applyTo` si querés reglas por tipo de archivo |
| Windsurf | `windsurf` | Automática | — |
| Gemini CLI | `gemini` | Manual | Requiere `@.gemini/skills-playbook.md` en `GEMINI.md` |
| Codex / `AGENTS.md` | `codex` | Manual | — |
| ChatGPT / GPTs | `generic` | Manual | Subir como conocimiento del Project |
| Continue.dev + local | `continue` | Automática | Mejor opción para modelos locales |
| Ollama / LM Studio | `generic` | Manual | Instalá 2-3 skills, no nueve. Subí `num_ctx` |
| aider | `generic` | Manual | `--read LLM_PLAYBOOK.md` |

Si el equipo usa varias herramientas a la vez: `--tool all`. Genera todos los formatos desde la misma
fuente, que es precisamente el problema que
[`universal-multi-ai-setup.md`](../03_architecture_patterns/universal-multi-ai-setup.md) resuelve.

## Verificar que quedó bien instalado

Tres comprobaciones, en orden de valor:

1. **La herramienta ve las skills.** En Claude Code, `/skills`. En las demás, pedile al modelo
   "listá las reglas o skills que tenés cargadas para este proyecto".
2. **Se activan cuando deben.** Decile "commitea esto" y verificá que mencione `safety-check` o el script
   de ship en vez de tirar `git commit` directo. Si no se activó, el problema casi siempre es la
   `description`, no la instalación.
3. **Los scripts corren.** `bash scripts/safety-check.sh` y `bash scripts/get-project-map.sh` desde la raíz
   del proyecto. Estos funcionan igual con cualquier modelo — es la parte del framework que no se degrada.
