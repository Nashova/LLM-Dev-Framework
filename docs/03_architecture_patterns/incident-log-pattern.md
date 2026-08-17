# Patrón: catálogo de incidentes reales (por qué funciona)

Plantilla lista para copiar en [`docs/02_governance_templates/change-safety-template.md`](../02_governance_templates/change-safety-template.md) — este documento explica el PATRÓN y por qué vale la pena mantenerlo, con más profundidad que la plantilla misma.

## La idea central

Un catálogo append-only, numerado, de incidentes REALES (no hipotéticos) que rompieron algo, con la causa raíz exacta identificada y la regla concreta que nació de ese incidente. Cada entrada es autocontenida: alguien que llega buscando ayuda para un síntoma que está viendo AHORA debería poder reconocer si su problema ya está documentado, leyendo solo el título y la primera línea.

## Por qué "real" es la palabra clave

Es tentador poblar este documento con reglas generales de buenas prácticas ("siempre valida el input", "nunca hardcodees credenciales") — son ciertas, pero no son lo que hace valioso a ESTE documento en particular. Ya existen mil recursos genéricos de buenas prácticas. Lo que este catálogo aporta que nada más puede aportar es la causa raíz EXACTA de un problema que YA pasó en ESTE proyecto, con el contexto específico (qué herramienta, qué versión, qué configuración del cliente) que hizo que ese problema apareciera. Esa especificidad es imposible de generalizar de antemano — solo se descubre viviéndola.

Un catálogo con 10 entradas reales, específicas, con causa raíz verificada, es más útil que uno con 50 reglas genéricas — porque las 10 reales van a volver a ser exactamente relevantes la próxima vez que alguien toque esa misma área del sistema, y las 50 genéricas probablemente no aportan nada que un LLM o un desarrollador senior no supieran ya.

## Por qué numerado y append-only

- **Numerado:** permite que otros documentos referencien una entrada específica (`ver change-safety.md §7`) de forma estable. Renumerar rompe esas referencias silenciosamente — un error real que puede pasar al fusionar dos ramas que agregaron entradas en paralelo (dos personas eligiendo el mismo "siguiente número disponible" sin saberlo). La forma de evitarlo: SIEMPRE agregar al final con el siguiente número, nunca insertar en el medio ni renumerar.
- **Append-only:** la historia de qué se intentó y qué no funcionó es información valiosa en sí misma. Si un incidente similar vuelve a pasar de forma distinta, se agrega una entrada NUEVA que referencia a la anterior — no se edita la anterior para "actualizarla", porque eso borra el rastro de que el primer intento de solución no fue completo.

## Cuándo agregar una entrada

Cuando algo se rompió de una forma que NO era obvia de antemano, y alguien invirtió tiempo real en encontrar la causa raíz. Si la causa era obvia desde el principio (un typo, un error de sintaxis normal), no amerita una entrada — este catálogo es para el conocimiento que costó descubrir, no para cualquier bug.

## La sección de checklist como destilado

Muchos catálogos de este tipo terminan con una checklist corta de "antes de tocar X, revisa esto" — es el destilado de las entradas del catálogo en forma de preguntas de una línea, para el caso común donde alguien no tiene tiempo de leer el catálogo entero pero sí puede pasar 30 segundos por una checklist. Cada vez que se cierra una entrada nueva del catálogo, vale la pena preguntarse si merece también un ítem nuevo en la checklist.
