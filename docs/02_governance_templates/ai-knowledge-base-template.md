# Plantilla: base de conocimiento operativa para LLMs (Nivel 2)

> Copiar la estructura (no necesariamente cada archivo) a una carpeta nueva, deliberadamente separada de `Docs/01-04` — ver [`docs/00_philosophy/two-tier-documentation.md`](../00_philosophy/two-tier-documentation.md) para cuándo vale la pena crear esto en vez de seguir con un solo `architecture.md`. Nombre sugerido: `AI_Knowledge_Base/` o `.llm-context/` — cualquiera que comunique "operativo, no entregable".

## Estructura

```
AI_Knowledge_Base/
├── 00_INDEX.md              -- tabla de ruteo: "necesitas X → lee el documento Y"
├── 01_arquitectura_general.md
├── 02_modelo_de_datos.md
├── 03_endpoints_o_api.md
├── 04_servicios_y_jobs.md
├── 05_flujo_de_negocio_critico.md   -- el/los procesos donde un error cuesta más caro
├── 06_autenticacion.md
├── 07_frontend.md                   -- si aplica
├── 08_infraestructura_y_env_vars.md
├── 09_riesgos_y_deuda_conocidos.md
└── NN_...                           -- uno por dominio adicional que el proyecto necesite
```

No hace falta crear los 10 el mismo día — cada uno se escribe cuando hay superficie real de código para describir, igual que la regla de `02_governance_templates/README.md` para `Docs/01-04`. La única diferencia real de este nivel es que estos documentos se **generan y corrigen leyendo el código real**, no se redactan desde cero por criterio — cada afirmación debería poder rastrearse a un archivo/línea real.

## `00_INDEX.md` — plantilla

```markdown
# Índice — Base de Conocimiento

> Generado/auditado por última vez: [fecha]. Ver la nota de frescura de cada documento individual antes de confiar en el detalle.

| Necesitas | Lee |
|---|---|
| Arquitectura general, mapa de componentes | `01_arquitectura_general.md` |
| Modelo de datos / esquema | `02_modelo_de_datos.md` |
| Endpoints / contrato de API | `03_endpoints_o_api.md` |
| [agregar una fila por documento] | |

## Problemas conocidos que NO hay que "descubrir" de nuevo

<!-- TODO: lista corta de gotchas de infraestructura/config que ya se saben y no están en ningún otro lado -- rutas rotas, servicios que no levantan con la instrucción documentada, notas pendientes de alguien del equipo. Se mantiene corta a propósito -- si crece mucho, la mayoría de sus entradas probablemente merecen ser una entrada real en change-safety.md en vez de una línea suelta aquí. -->
```

## Encabezado obligatorio de cada documento de dominio

```markdown
# NN — [Dominio]

> Audiencia: un LLM o desarrollador **sin contexto previo** del proyecto. Léelo completo antes de tocar código de este dominio.
> Generado/verificado el [fecha] a partir del código real en [ruta/rama]. Verificación profunda pendiente si aplica.

<!-- Parche puntual del [fecha]: si algo cambió después de la generación original y no amerita reescribir todo el documento, agregarlo aquí como párrafo fechado -- ver docs/00_philosophy/doc-freshness-strategy.md del framework para el patrón completo. -->
```

## Convenciones que vale la pena declarar una sola vez en `00_INDEX.md` o en `AGENT_GUIDE.md`

- **Vocabulario mixto**: si el proyecto mezcla idiomas o jerga propia del negocio con términos técnicos en otro idioma (pasa seguido en equipos no angloparlantes trabajando sobre frameworks en inglés), declarar la convención una vez ("el código mezcla español e inglés: `solicitar_adi`, `findPartNumbers` — al buscar, intentar en ambos idiomas") en vez de que cada sesión lo redescubra buscando solo en un idioma.
- **Verificación con cita exacta**: cada afirmación sobre "cómo funciona hoy" debería poder anclarse a `archivo:línea` real, no a una paráfrasis de memoria — esto es lo que separa un documento de Nivel 2 confiable de uno que empieza a acumular imprecisiones silenciosas.
- **Nunca sincronizar esta carpeta al proceso de generación de entregables** (Word/PDF para el cliente) que el proyecto pueda tener — es la distinción central del Nivel 2, ver `two-tier-documentation.md`.
