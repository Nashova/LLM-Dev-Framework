---
name: small-model-handoff
description: Preparar una tarea para que un modelo pequeño o local (7B-30B, Ollama, LM Studio, o cualquier LLM con contexto y razonamiento limitados) la ejecute de forma confiable. Úsala cuando el usuario diga que va a trabajar con un modelo local, sin internet, con presupuesto limitado, o cuando pida "que esto funcione con un modelo chico". También cuando un modelo pequeño ya esté fallando en una tarea y haya que reformularla.
---

# Preparar trabajo para un modelo pequeño

Un modelo pequeño no es un modelo grande lento: **falla en cosas distintas**. Es razonablemente bueno
siguiendo un procedimiento explícito y corto, y malo en exactamente lo que un framework como este puede
suplir con estructura.

| Falla en | Es aceptable en |
|---|---|
| Planificar varios pasos y mantener el plan | Ejecutar UN paso descrito literalmente |
| Decidir cuándo detenerse y preguntar | Rellenar una plantilla dada |
| Mantener coherencia en contexto largo | Leer un archivo corto y responder sobre él |
| Reconocer que no sabe algo | Aplicar una regla explícita ya escrita |
| Elegir entre varias reglas cuál aplica | Seguir la única regla que le pasaste |

**La consecuencia de diseño**: no le pidas juicio. Convertí el juicio en estructura antes de entregarle la
tarea. Todo lo que un modelo grande resuelve razonando, un modelo chico lo resuelve solo si vos ya lo
resolviste en la forma de la tarea.

## Las cinco transformaciones

### 1. Un paso por turno, con criterio de terminado mecánico

Mal: *"Agregá autenticación al proyecto"*.
Bien (ejemplo): *"Abrí `src/api/routes.py`. Agregá el decorador `@requires_auth` a las tres funciones que empiezan
con `admin_`. No toques nada más. Terminaste cuando `grep -c '@requires_auth' src/api/routes.py` devuelve 3."*

El criterio de terminado tiene que ser **verificable por un comando**, no por opinión. Un modelo chico no
sabe cuándo terminó; un `grep` sí.

### 2. Contexto mínimo y dirigido

No le pases el repo. No le pases el `AGENT_GUIDE.md` completo (son cientos de líneas y va a perder el
hilo). Pasale **la sección específica** que aplica a esta tarea, y nada más.

Regla práctica: si el contexto no cabe cómodamente en un tercio de su ventana, es demasiado. El resto del
contexto es lo que le hace perder la instrucción original.

### 3. Los scripts hacen el trabajo determinista

Esto es donde el framework rinde más con modelos chicos. Todo lo que ya está encapsulado en un script **no
requiere que el modelo razone**:

```bash
bash scripts/get-project-map.sh        # estado del repo: no lo tiene que deducir
bash scripts/safety-check.sh           # validación: no la tiene que recordar
bash scripts/ship.sh -m "mensaje"      # entrega: no tiene que reconstruir la secuencia de git
bash scripts/validate-knowledge-base.sh
```

Un modelo chico corriendo `safety-check` da un resultado **idéntico** al de un modelo grande corriéndolo.
Ahí no hay degradación. Movele al script todo lo que puedas.

### 4. Plantillas en vez de redacción libre

Un modelo chico llenando `docs/02_governance_templates/*.md` produce algo utilizable. El mismo modelo
redactando el mismo documento desde cero produce algo genérico y probablemente falso.

Dale la plantilla con los campos vacíos y una instrucción por campo. La estructura hace el trabajo que su
razonamiento no puede hacer.

### 5. Verificación externa después de cada paso

No le pidas que se auto-verifique — no es confiable. Verificá vos (o un script) después de cada paso, antes
de darle el siguiente. Un error no detectado en el paso 2 se amplifica en los pasos 3 a 8.

## Lo que NO se le delega, nunca

Estas tareas requieren el juicio que precisamente no tiene. Si no hay un modelo grande disponible, las hace
una persona:

- Decidir el modelo de datos o el de control de acceso.
- Cualquier cosa que toque un ambiente compartido o producción.
- Escribir la entrada de un incidente (requiere identificar la causa raíz).
- Decidir si algo "está en uso operativo real".
- Auditar código en busca de problemas de seguridad.
- Elegir entre dos diseños razonables con un trade-off de negocio.

## Plantilla de handoff

Pasale esto, literalmente, sustituyendo lo que va entre corchetes:

```
TAREA: [una sola acción, un solo archivo]
ARCHIVO: [ruta exacta]
CONTEXTO: [pegá aquí SOLO la regla o sección que aplica — 5 a 20 líneas]

HACÉ EXACTAMENTE ESTO:
1. [acción concreta]
2. [acción concreta]

NO HAGAS:
- No modifiques ningún otro archivo.
- No refactorices nada que ya funcione.
- Si algo no está claro, escribí "NECESITO ACLARACIÓN: <qué>" y detenete. No adivines.

TERMINASTE CUANDO: [comando exacto] devuelve [resultado exacto].
```

La línea de "NECESITO ACLARACIÓN" es la más importante: un modelo chico **no** va a preguntar por su
cuenta, hay que darle el permiso y el formato explícitos para hacerlo.

## Checklist

- [ ] La tarea es un solo paso, sobre un solo archivo.
- [ ] El criterio de terminado es un comando, no una opinión.
- [ ] El contexto es la sección mínima, no el documento completo.
- [ ] Todo lo determinista está en un script, no en la instrucción.
- [ ] Hay una plantilla si el output es un documento.
- [ ] Yo (o un script) verifico antes de darle el paso siguiente.
- [ ] Ninguna de las tareas "que no se delegan" está en el lote.

## Relacionado

- `docs/00_philosophy/working-with-small-models.md` — la guía completa del operador, con la escalera de
  degradación y qué esperar de cada tamaño de modelo.
- `docs/00_philosophy/why-scripts-not-instructions.md` — la razón por la que los scripts son el gran
  igualador entre modelos.
- `docs/01_bootstrap/llm-setup-guide.md` — cómo instalar estas skills en un runtime local.
