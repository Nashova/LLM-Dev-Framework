# Dos niveles de documentación: lo que se entrega, y lo que el LLM necesita para navegar

Extiende `doc-freshness-strategy.md`. Ese documento resuelve "cómo evitar que la documentación mienta con el tiempo". Este resuelve un problema distinto que aparece a cierta escala: un solo documento de arquitectura deja de ser suficiente, y la forma correcta de crecer NO es agregar más secciones al mismo archivo — es reconocer que hay dos tipos de documentación con propósitos, audiencias y ritmos de cambio completamente distintos, y separarlos desde la estructura de carpetas.

## Los dos niveles

**Nivel 1 — documentación de entrega.** La que el cliente/negocio va a leer, la que eventualmente se convierte en un artefacto formal (manual de usuario, documento de arquitectura firmado, propuesta), la que cambia poco y cuando cambia es una decisión consciente ("actualizamos el manual porque salió la v2"). Vive en la estructura de `Docs/01_business_analysis/` a `Docs/04_product_roadmap/` que ya define `02_governance_templates/README.md`.

**Nivel 2 — base de conocimiento operativa.** La que un LLM (o un desarrollador nuevo) necesita para orientarse en un sistema real sin leer todo el código cada vez: qué modelos existen, qué endpoints hay, cómo fluye el dato crítico del negocio, qué decisiones no obvias existen y por qué. Cambia constantemente (cada sesión que toca código puede volver algo de esto un poco impreciso), se genera y corrige a partir del código real, y **nunca se promete al cliente como entregable** — es infraestructura interna del equipo (humano + IA), no un producto.

## Por qué la separación importa (no es solo organización de carpetas)

Mezclar los dos niveles en el mismo documento produce el peor resultado posible: un documento que necesita actualizarse constantemente (porque describe código real) pero que además tiene la expectativa de calidad/formalidad de un entregable (porque vive junto a los que sí lo son) — nadie tiene tiempo de mantenerlo con ese estándar a ese ritmo, así que empieza a mentir, y como está mezclado con contenido que sí se cuida, nadie sospecha que la parte que miente está justo ahí.

Separarlos permite tratarlos con reglas distintas y honestas:
- El Nivel 1 puede exigirse impecable, precisamente porque cambia poco.
- El Nivel 2 puede aceptar explícitamente estar "parcialmente desactualizado" (ver `doc-freshness-strategy.md`) sin que eso contamine la percepción de calidad de lo que sí se entrega.

## Cuándo pasar de "un architecture.md" a una base de conocimiento en Nivel 2

No es necesario desde el día 1 — `architecture.md` (la plantilla de `02_governance_templates/`) es suficiente para un proyecto chico o mediano. La señal de que hace falta partirlo es cuando `architecture.md` empieza a tener secciones de 500+ líneas por dominio (modelo de datos completo, catálogo de endpoints, mapeo de servicios) y encontrar algo específico ahí requiere `Ctrl+F` en vez de saber a qué documento ir. En ese punto:

1. Crear una carpeta operativa separada (por ejemplo `AI_Knowledge_Base/`; cualquier nombre que comunique "esto es para navegar, no para entregar" funciona) — deliberadamente **fuera** de la estructura `01-04` del Nivel 1, para que no se confunda con documentación de entrega ni se incluya por accidente en cualquier proceso de generación de entregables (PDF/Word) que el proyecto tenga.
2. Partir el contenido por dominio, numerado, cada archivo con un propósito claro y una sola responsabilidad (arquitectura general, modelo de datos, endpoints, servicios, el flujo de negocio más crítico, autenticación, frontend, infraestructura, riesgos conocidos — la lista exacta depende del proyecto).
3. Cada documento lleva un encabezado de frescura explícito ("Generado el [fecha] a partir del código real. Verificación profunda pendiente.") — ver la plantilla completa en [`ai-knowledge-base-template.md`](../02_governance_templates/ai-knowledge-base-template.md).
4. Un índice/tabla de ruteo en `AGENT_GUIDE.md` ("¿Necesitas X? → lee el documento Y") — sin esto, tener 12 documentos numerados no es mejor que tener uno gigante, solo cambia dónde está perdido el LLM.

## La regla anti-duplicación (RAID) entre niveles y dentro del Nivel 2

Cuando aparecen varios documentos operativos (base de conocimiento + catálogo de incidentes + registro de deuda técnica + decisiones de arquitectura + seguimiento de requerimientos, ver `requirements-tracking-template.md`), la tentación de repetir un mismo hallazgo en dos lugares distintos ("por si alguien solo lee uno") es constante — y produce el problema clásico de dos copias que se desincronizan porque solo una se actualizó. Regla de bolsillo aplicable a cualquier proyecto con más de 2 documentos operativos: **cada tipo de conocimiento tiene UN hogar autoritativo**; cualquier otro documento que lo necesite lo referencia (un link, una cita corta), nunca lo copia. Un riesgo técnico transversal vive en el registro de deuda técnica, no repetido en cada documento que lo menciona; una decisión de arquitectura significativa vive en el registro de decisiones, no repetida en el documento de requerimiento que la originó.
