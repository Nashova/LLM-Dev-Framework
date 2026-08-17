# Trabajar con modelos pequeños o locales sin bajar la calidad del entregable

Este documento responde una pregunta concreta: **¿se puede usar este framework con un modelo local de
7B-30B, sin internet o sin presupuesto de API, y entregar algo bien armado?**

Sí, pero no haciendo lo mismo más lento. Hay que mover trabajo desde el modelo hacia la estructura.

## La tesis

Un framework de desarrollo con LLM tiene tres tipos de componente, y **solo uno se degrada con el tamaño
del modelo**:

| Componente | ¿Se degrada? | Por qué |
|---|---|---|
| **Scripts** (`safety-check`, `ship`, `get-project-map`, `validate-knowledge-base`) | **No** | Son deterministas. Un modelo de 7B corriendo `safety-check` obtiene el resultado **idéntico** a uno de frontera. |
| **Plantillas y checklists** | Casi no | Llenar campos definidos es mucho más fácil que redactar desde cero. |
| **Juicio** (elegir diseño, detectar causa raíz, saber cuándo preguntar) | **Sí, mucho** | Es exactamente lo que un modelo chico no tiene. |

De ahí sale la estrategia completa: **maximizá la proporción del trabajo que hacen los dos primeros**.
Un proyecto donde el 70% de las operaciones repetitivas están encapsuladas en scripts es un proyecto
donde un modelo chico rinde casi como uno grande. Un proyecto donde todo depende de que el modelo
reconstruya el procedimiento cada vez, no.

Esta es la misma tesis de [`why-scripts-not-instructions.md`](why-scripts-not-instructions.md), llevada a
su consecuencia extrema: **el script no sólo ahorra tokens — es el gran igualador entre modelos.**

## Qué esperar de cada tamaño

Aproximado y dependiente del modelo concreto, pero útil para calibrar:

| Tamaño | Sirve para | No le pidas |
|---|---|---|
| **~7B** | Ediciones mecánicas de un archivo nombrado, llenar una plantilla campo por campo, correr scripts, formatear | Nada que requiera elegir entre dos opciones |
| **~14B** | Lo anterior + funciones autocontenidas, tests de un caso conocido, activación de skills por descripción | Refactors que cruzan archivos, diagnóstico de causa raíz |
| **~30B** | Lo anterior + refactor acotado en 2-3 archivos, revisión de código en un archivo, resumir un documento | Decisiones de arquitectura, seguridad, control de acceso |
| **Frontera** | Todo lo del framework, incluido el juicio | — |

## La escalera de degradación

Cuando bajás de modelo, aplicá estos peldaños **en orden**. Cada uno compra calidad a cambio de más
intervención tuya:

### 1. Reducí el contexto (el de mayor retorno)

Un modelo chico con demasiado contexto no es más informado: **pierde la instrucción original**. No le pases
el repo ni el `AGENT_GUIDE.md` completo. Pasale la sección específica, de 5 a 20 líneas.

Regla práctica: si el contexto no cabe cómodamente en un tercio de la ventana, es demasiado. Y verificá la
ventana **real** configurada — en Ollama, `num_ctx` suele estar por debajo de la del modelo, y el síntoma
es que "olvida" instrucciones sin ningún error visible.

### 2. Un paso por turno, con criterio de terminado mecánico

Mal: *"agregá autenticación"*. Bien (ejemplo): *"en `src/routes.py`, agregá el decorador `@requires_auth` a las tres
funciones que empiezan con `admin_`. Nada más. Terminaste cuando `grep -c '@requires_auth' src/routes.py`
devuelve 3."*

El criterio de terminado tiene que ser **un comando**, no una opinión. Un modelo chico no sabe cuándo
terminó; un `grep` sí.

### 3. Movele todo lo determinista a un script

Si una operación se repite y tiene pasos fijos, no la expliques: encapsulala. Cada script nuevo es trabajo
que el modelo ya no puede hacer mal.

### 4. Plantilla en vez de redacción libre

Un modelo chico llenando `docs/02_governance_templates/*.md` produce algo utilizable. El mismo modelo
redactando el mismo documento desde cero produce algo genérico y probablemente falso.

### 5. Verificación externa después de cada paso

No le pidas que se auto-verifique: no es confiable. Verificá vos, o con un script, antes de darle el paso
siguiente. Un error no detectado en el paso 2 se amplifica en los pasos 3 a 8.

### 6. Dale permiso explícito para no saber

Un modelo chico **no va a preguntar por su cuenta** — va a inventar. Hay que darle el formato:

> Si algo no está claro, respondé exactamente `NECESITO ACLARACION: <qué>` y detenete. No adivines.

Es la instrucción de una línea con mejor retorno de todas. Sin ella, la ambigüedad se resuelve con una
alucinación plausible; con ella, se resuelve con una pregunta.

## Lo que NO se delega a un modelo pequeño

Estas tareas requieren el juicio que precisamente no tiene. Si no hay un modelo grande disponible, **las
hace una persona** — no las hace un modelo chico "con cuidado":

- Diseñar el modelo de datos o el de control de acceso.
- Cualquier cosa contra un ambiente compartido o producción.
- Diagnosticar la causa raíz de un incidente (y por lo tanto, escribir su entrada en `change-safety.md`).
- Decidir si algo "está en uso operativo real".
- Auditar seguridad.
- Elegir entre dos diseños razonables con un trade-off de negocio.
- Aprobar un PR.

## El modelo híbrido (lo que recomendamos)

No es "modelo grande o modelo chico": es **usar cada uno donde rinde**.

| Fase | Quién | Por qué |
|---|---|---|
| Discovery, arquitectura, decisiones | Modelo grande, o una persona | Es juicio puro |
| Descomponer en pasos ejecutables | Modelo grande | Ver [`small-model-handoff`](../../skills/small-model-handoff/SKILL.md) |
| Ejecutar cada paso | Modelo chico / local | Es mecánico y verificable |
| Verificar | Scripts | No se degrada |
| Revisión final antes del PR | Modelo grande, o una persona | Es donde se atrapa lo que el chico no vio |

Un modelo grande gastando cinco minutos en producir un plan de doce pasos bien especificados, y un modelo
local ejecutándolos, entrega mejor que el modelo local solo — y mucho más barato que el grande haciendo
todo. La skill [`small-model-handoff`](../../skills/small-model-handoff/SKILL.md) existe precisamente para
que el modelo grande prepare ese plan en el formato correcto.

## Instalación concreta

Ver [`llm-setup-guide.md`](../01_bootstrap/llm-setup-guide.md), sección **Modelos locales**. Dos cosas que
importan más que el resto:

1. **Instalá pocas skills, no las nueve.** Para un modelo local arrancá con
   `small-model-handoff`, `safe-change-gate` y `verify-before-claiming`. El playbook completo compite con
   la tarea real por contexto.
2. **Continue.dev con Ollama detrás** es la mejor combinación: tiene activación por descripción, así que
   con 14B o más las skills se cargan solas y no tenés que pegar el playbook a mano.

## El criterio para saber si está funcionando

No es "el modelo escribe código lindo". Es: **¿el entregable pasa las mismas verificaciones mecánicas que
pasaría con un modelo grande?**

```bash
bash scripts/safety-check.sh
bash scripts/validate-knowledge-base.sh
```

Si pasan, y el checklist de [`safe-change-gate`](../../skills/safe-change-gate/SKILL.md) está recorrido
por alguien con criterio, el tamaño del modelo que escribió las líneas importa mucho menos de lo que
parece. Ese es el punto del framework entero: **que la calidad del entregable dependa de la estructura y
no de la suerte del turno.**

## Relacionado

- [`why-scripts-not-instructions.md`](why-scripts-not-instructions.md) — la base de todo esto.
- [`../../skills/small-model-handoff/SKILL.md`](../../skills/small-model-handoff/SKILL.md) — la plantilla de handoff.
- [`../01_bootstrap/llm-setup-guide.md`](../01_bootstrap/llm-setup-guide.md) — instalación por herramienta.
- [`collaboration-style.md`](collaboration-style.md) §1 — pedir criterio en vez de adivinar, que con un
  modelo chico pasa de recomendación a requisito.
