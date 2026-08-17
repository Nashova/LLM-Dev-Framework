# Por qué comandos, no instrucciones en prosa

## El problema

Es posible describirle a un LLM, en prosa, todo el procedimiento de "verifica que el servidor esté sano": qué contenedores deberían estar corriendo, qué puerto debería responder, qué logs mirar. Funciona. También se vuelve a reconstruir, con variaciones sutiles y a veces con errores, cada vez que alguien (humano o LLM) necesita hacerlo — y cada reconstrucción gasta tiempo/tokens en llegar al mismo resultado que ya se había llegado antes.

## El patrón

Cualquier procedimiento que se va a repetir más de dos o tres veces se convierte en un script real (`.sh`/`.ps1`), no en una instrucción en un documento que alguien tiene que traducir a comandos cada vez. El documento de referencia (`AGENT_GUIDE.md` o equivalente) apunta al script con una tabla de una línea por comando, no reexplica el procedimiento.

Beneficios concretos, no solo estéticos:

- **Determinismo.** Un script hace exactamente lo mismo cada vez. Una instrucción en prosa, interpretada por un LLM con temperatura no-cero, puede variar en detalles pequeños que importan (¿el healthcheck pega a `localhost` o a la IP pública? ¿se reinicia el proxy después del deploy o no?).
- **El script captura el conocimiento del "por qué".** Los comentarios dentro de un script sobreviven mejor que el conocimiento tácito de "ah sí, hay que reiniciar el proxy después porque cachea DNS" — que se pierde entre sesiones si solo vive en la cabeza de quien lo descubrió.
- **Costo marginal casi cero después de la primera vez.** Escribir el script cuesta una sesión. Cada uso después cuesta una línea de comando en vez de una negociación de varios turnos sobre qué hacer exactamente.
- **El script es auditable.** Un humano puede leer 40 líneas de bash y saber exactamente qué va a pasar antes de correrlo. Una instrucción en prosa que un LLM va a "interpretar y ejecutar" no da esa misma garantía.

## Qué NO convertir en script

Las decisiones de juicio (¿este código está bien diseñado?, ¿este enfoque es el correcto para este caso?) no se automatizan — ahí es exactamente donde el LLM aporta valor por sobre un script. La automatización es para lo mecánico y repetitivo (chequeos de formato, flujo de commit/push/PR, healthchecks), nunca para reemplazar el criterio.

## El script "todo en uno" (`ship`)

Un patrón que vale la pena replicar tal cual: un solo comando que encadena el flujo completo de "terminé de programar esto" — chequeo de seguridad → commit → (opcional) deploy → push → crear/actualizar el Pull Request. Ver `scripts/ship.sh` del framework.

La razón de encadenarlo en un solo comando en vez de dejarlo como 4 pasos separados: los pasos intermedios (¿ya hice commit? ¿ya hice push? ¿ya hay un PR abierto o hay que crear uno nuevo?) son exactamente el tipo de estado que un LLM puede perder de vista entre turnos de una conversación larga, y equivocarse ahí (crear un PR duplicado, olvidar el push) es más caro de corregir que el costo de simplemente encadenar el flujo completo cada vez.
