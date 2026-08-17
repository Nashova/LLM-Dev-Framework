# Skills del framework

Una **skill** es un protocolo que se auto-dispara según la forma de la tarea, en vez de depender de que
el LLM recuerde leer un párrafo. La diferencia importa: una regla escrita en un documento de 400 líneas
se lee la primera sesión y se olvida; una skill con la descripción correcta se activa exactamente cuando
hace falta.

Estas nueve skills son **propias del framework** (MIT, sin dependencias de terceros) y codifican su
filosofía en forma ejecutable. Para skills de stack específico (React, .NET, Docker…) ver
[`CATALOG.md`](CATALOG.md), que apunta a los repos upstream sin redistribuirlos.

## Las skills

| Skill | Se dispara cuando | Evita |
|---|---|---|
| [verify-before-claiming](verify-before-claiming) | Estás por afirmar que algo existe, no existe, o está en uso | La clase de error más caro: una afirmación falsa dicha con confianza |
| [project-onboarding](project-onboarding) | Empieza una sesión o cambiás de contexto | Gastar turnos adivinando el estado del repo |
| [safe-change-gate](safe-change-gate) | Vas a tocar datos, permisos, CI/CD, scripts o archivos protegidos | La clase entera de incidente que el checklist previene |
| [ship-changes](ship-changes) | El usuario dice "commitea", "sube", "despliega" | Saltarse el safety-check y desplegar a producción sin autorización |
| [incident-capture](incident-capture) | Algo se rompió y ya se diagnosticó la causa raíz | Que la lección se pierda y el error se repita |
| [doc-drift-check](doc-drift-check) | Antes de un PR o release | Documentación que miente sobre el código |
| [requirements-intake](requirements-intake) | Llega una petición de negocio sin especificar | Adivinar decisiones que sólo el negocio puede tomar |
| [pre-publication-audit](pre-publication-audit) | Un repo privado va a volverse público | Filtrar datos de cliente o secretos en el historial |
| [small-model-handoff](small-model-handoff) | Vas a trabajar con un modelo local o pequeño | Pedirle juicio a un modelo que no puede darlo |

Si tuvieras que instalar sólo dos: **`verify-before-claiming`** y **`safe-change-gate`**. Son las que
atacan los dos modos de falla más caros.

## Instalación

Una skill se escribe **una sola vez** en formato Agent Skills (`SKILL.md` con frontmatter `name` +
`description`) y el instalador la traduce al formato nativo de cada herramienta. No se mantienen copias
a mano.

```bash
# Ver qué hay disponible
bash scripts/install-skills.sh --list

# Instalar todas en un proyecto, para Claude Code
bash scripts/install-skills.sh --target /ruta/a/mi-proyecto --tool claude

# Sólo dos skills, para Cursor
bash scripts/install-skills.sh --target . --tool cursor --skills verify-before-claiming,safe-change-gate

# Todas las herramientas a la vez (útil si el equipo usa varias)
bash scripts/install-skills.sh --target . --tool all

# Ver qué haría sin escribir nada
bash scripts/install-skills.sh --target . --tool all --dry-run
```

En Windows: `powershell -File scripts/install-skills.ps1 -Target . -Tool claude`. Ambos scripts son
funcionalmente equivalentes y producen los mismos archivos.

### Qué genera para cada herramienta

| `--tool` | Genera | Activación |
|---|---|---|
| `claude` | `.claude/skills/<n>/SKILL.md` | Automática por `description` |
| `cursor` | `.cursor/rules/<n>.mdc` | Automática (`alwaysApply: false`, el modelo decide) |
| `copilot` | `.github/instructions/<n>.instructions.md` | Automática (`applyTo: '**'`) |
| `windsurf` | `.windsurf/rules/<n>.md` | Automática (`trigger: model_decision`) |
| `continue` | `.continue/rules/<n>.md` | Automática — la vía para modelos locales vía Continue.dev |
| `gemini` | (generado) `.gemini/skills-playbook.md` | Manual: agregá `@.gemini/skills-playbook.md` a tu `GEMINI.md` |
| `codex` | `.agent-skills-playbook.md` | Manual: referencialo desde tu `AGENTS.md` |
| `generic` | `LLM_PLAYBOOK.md` | Manual: pegalo como system prompt |

Las tres últimas concatenan todas las skills en **un solo archivo con tabla de ruteo** al principio. Es
la vía para cualquier herramienta o modelo sin soporte nativo de skills — ver
[`working-with-small-models.md`](../docs/00_philosophy/working-with-small-models.md).

Los detalles por herramienta (incluido ChatGPT, Ollama y LM Studio) están en
[`docs/01_bootstrap/llm-setup-guide.md`](../docs/01_bootstrap/llm-setup-guide.md).

### Seguridad al instalar

El instalador **nunca sobrescribe un archivo que no generó él mismo**. Si ya tenés una regla escrita a
mano en `.cursor/rules/`, la deja intacta y avisa. Con `--force` la respalda como `<archivo>.bak` antes de
reemplazarla. Los archivos que sí generó se resincronizan en silencio, así que correr el instalador de
nuevo después de editar una skill es seguro e idempotente.

## Escribir una skill nueva

```
skills/mi-skill/SKILL.md
```

```markdown
---
name: mi-skill
description: Qué hace y CUÁNDO usarla. Incluí los disparadores literales que un usuario diría.
---

# Título

Cuerpo: el procedimiento, los antipatrones, un checklist.
```

Lo único que determina si una skill se activa es su **`description`**. Reglas que funcionan:

- Empezá con el verbo de la acción, no con "Esta skill...".
- Incluí los **disparadores literales**: las frases exactas que un usuario diría ("commitea esto",
  "se cayó producción"). El modelo hace *matching* contra esas frases.
- Declará explícitamente cuándo **NO** usarla. Una skill que se activa de más es peor que una que no se
  activa: consume contexto y entrena al usuario a ignorarla.
- Mantené el cuerpo bajo ~200 líneas. Si necesita más, partilo en archivos auxiliares que el `SKILL.md`
  referencie con rutas relativas.

Después de crearla, corré el instalador de nuevo para propagarla a todas las herramientas.

## Relacionado

- [`docs/03_architecture_patterns/skills-and-triggers.md`](../docs/03_architecture_patterns/skills-and-triggers.md)
  — cuándo un protocolo merece ser skill y cuándo alcanza con un párrafo.
- [`docs/03_architecture_patterns/universal-multi-ai-setup.md`](../docs/03_architecture_patterns/universal-multi-ai-setup.md)
  — la misma idea aplicada a la guía de entrada.
- [`CATALOG.md`](CATALOG.md) — skills externas por stack, con su licencia.
