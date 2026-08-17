# Catálogo de skills externas

Skills de terceros que complementan bien este framework, agrupadas por para qué sirven.

> **Este framework no las redistribuye.** Cada fila apunta al repositorio upstream con su licencia
> verificada. La razón es doble: (a) redistribuir contenido de terceros en un repo MIT exige respetar y
> propagar su licencia, y varias de las skills que circulan no declaran ninguna; (b) upstream se
> actualiza y una copia vendorizada envejece en silencio. Instalá desde la fuente.
>
> **Antes de adoptar cualquier skill de esta lista o de fuera de ella**: verificá su licencia contra el
> repo real, no contra este catálogo ni contra el resumen de una búsqueda. Un resumen de búsqueda web
> puede enumerar archivos que no existen — ver
> [`verify-before-claiming`](verify-before-claiming/SKILL.md).

## Cómo instalar una skill externa

La mayoría de los repos de skills siguen la convención `<repo>/skills/<nombre>/SKILL.md`. Copiá **solo la
carpeta de la skill** que te interesa, no el repo entero:

```bash
git clone --depth 1 https://github.com/<autor>/<repo> /tmp/skills-upstream
cp -r /tmp/skills-upstream/skills/<nombre> .claude/skills/<nombre>
```

Dejá una nota de procedencia junto a la copia (`_source.md` con repo, versión/commit y licencia). Sin eso,
en seis meses nadie sabe de dónde salió ni si tiene actualizaciones — y si el repo es público, tampoco si
se está cumpliendo su licencia.

## Meta: crear y operar skills

| Skill / repo | Para qué | Licencia |
|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) → `skill-creator` | Crear skills nuevas, optimizar su `description`, correr evals de activación | Apache-2.0 |
| [anthropics/skills](https://github.com/anthropics/skills) → `mcp-builder` | Construir servidores MCP | Apache-2.0 |
| [obra/superpowers](https://github.com/obra/superpowers) | 14 sub-skills de metodología (TDD, brainstorming, verification-before-completion, git worktrees, agentes en paralelo) | MIT (Jesse Vincent) |

`superpowers` es una **metodología completa**, no una skill suelta: adoptarla es un compromiso de proceso.
Vale la pena evaluar `verification-before-completion` por separado — resuelve el mismo problema que
nuestro `doc-drift-check` desde otro ángulo.

## Documentos y entregables

| Skill / repo | Para qué | Licencia |
|---|---|---|
| [anthropics/skills](https://github.com/anthropics/skills) → `docx`, `pdf`, `pptx`, `xlsx` | Generar y leer entregables de Office/PDF reales | Apache-2.0 |
| [anthropics/skills](https://github.com/anthropics/skills) → `webapp-testing` | E2E con Playwright | Apache-2.0 |

Las de Office encajan directo con el Nivel 1 de
[`two-tier-documentation.md`](../docs/00_philosophy/two-tier-documentation.md): la documentación que sí se
entrega al cliente como artefacto formal.

## Backend y bases de datos

| Skill / repo | Para qué | Licencia |
|---|---|---|
| [Aaronontheweb/dotnet-skills](https://github.com/Aaronontheweb/dotnet-skills) | 34 skills de C#/.NET: coding standards, concurrencia, DI, configuración, performance de tipos y de queries, snapshot testing, Testcontainers | MIT (Aaron Stannard) |

Para .NET este repo es el más completo que conocemos. Combinaciones útiles: `csharp-concurrency-patterns`
con nuestro [`safe-change-gate`](safe-change-gate/SKILL.md), y `testcontainers` cuando el proyecto necesite
integration tests reales en vez de una base compartida — el incidente de la tarea "test setup" que hacía
`DROP DATABASE` (ver [`case-study-multi-repo-ecosystem.md`](../examples/case-study-multi-repo-ecosystem.md))
es exactamente lo que Testcontainers previene.

## Frontend y diseño

| Skill / repo | Para qué | Licencia |
|---|---|---|
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | Ingeniería de animación a nivel de código: curvas, duraciones, springs, gotchas de Framer Motion. Incluye una variante que **audita** motion ya escrito | MIT |
| [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) | Audita UI contra el checklist de Vercel (a11y, forms, touch, spacing, dark mode, i18n). Stack-agnóstico | MIT |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | Referencia de reglas UI/UX priorizadas | MIT |

**Ojo con el solapamiento**: las skills de *construir* frontend compiten entre sí — elegí una por
proyecto, no tres, o el modelo recibe tres criterios contradictorios. Las de *auditar* código ya escrito
son complementarias y se pueden acumular.

Todas aplican **solo si el proyecto tiene una SPA**. Ver la sección de alcance del
[`README`](../README.md) principal.

## Agentes y context engineering

| Skill / repo | Para qué | Licencia |
|---|---|---|
| [agent-skills-context-engineering](https://github.com/agent-skills/context-engineering) | 18 sub-skills para construir agentes: context engineering, patrones multi-agente, sistemas de memoria, diseño de herramientas | MIT |

Relevante si tu proyecto **es** un sistema de agentes. Si sólo usás un LLM para desarrollar, no aplica.

## Lo que deliberadamente NO está en este catálogo

| Qué | Por qué |
|---|---|
| Skills sin licencia declarada | Sin licencia no hay permiso de redistribución, y muchas veces tampoco de uso comercial. Si querés usar una, pedile al autor que declare licencia. |
| `frontend-design` del repo `anthropics/claude-code` | Cubierta por los Términos Comerciales de Anthropic, no por una licencia OSS. Usable desde la herramienta, **no** redistribuible. |
| Skills de proceso interno / de cliente | Un flujo operativo atado a una empresa concreta (su correo, su gestor de tareas, su nomenclatura) no es reusable y filtra información. Vive en el repo privado de esa organización, no acá. |
| Frameworks de 40 MB con SDK y CLI propios | Adoptarlos es un compromiso mayor que el framework entero. Evaluables, no recomendables por defecto. |

## Criterio para agregar algo a este catálogo

1. **Licencia verificada** en el repo real, permisiva (MIT / Apache-2.0 / BSD).
2. **Genérica**: no atada a una empresa, cliente o proceso interno.
3. **No redundante** con una skill propia del framework ni con capacidades nativas de la herramienta
   (una skill de "buscar archivos" es redundante donde el agente ya tiene grep y glob nativos).
4. **Mantenida**: commits en los últimos ~12 meses, o tan estable que no los necesite.
5. **Alcance declarado**: dice a qué tipo de proyecto aplica y a cuál no.
