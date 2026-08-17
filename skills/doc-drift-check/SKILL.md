---
name: doc-drift-check
description: Detectar documentación que ya no dice la verdad sobre el código. Úsala antes de un PR o release, cuando el usuario diga "revisa la documentación", "está actualizado?", "valida las citas", o después de un refactor que movió o renombró archivos. También cuando encuentres una discrepancia entre lo que un doc afirma y lo que el código hace.
---

# Detectar drift entre documentación y código

La documentación **se va a desactualizar**. Es inevitable: nadie recuerda tocar cuatro documentos cada vez
que cambia una línea. Lo que importa no es pretender que no pase, es tener un mecanismo que lo haga
**visible** cuando pasa.

## Paso 1 — Chequeo mecánico

```bash
bash scripts/validate-knowledge-base.sh    # o: powershell -File scripts/validate-knowledge-base.ps1
```

Verifica que **el archivo** de cada cita tipo `` `ruta/archivo.ext:123` `` exista en el código activo,
incluidas ramas no promovidas.

**Lo que este script NO hace, y hay que saberlo**: no valida que el número de línea siga siendo el
correcto. Una cita `auth.py:45` pasa el chequeo aunque la función se haya movido a la línea 200. Para eso
hay que anclar contenido, no rutas — si una cita es crítica, citá el nombre del símbolo además de la línea.

Convenciones que el validador respeta, para citas que apuntan a algo que todavía no existe:

- `(nuevo)`, `(propuesto)`, `(template)`, `(ejemplo)`, `(generado)` en la misma línea → se saltea la cita.
  Usalas cuando documentes un archivo que el usuario va a crear, no uno que ya existe.

## Paso 2 — Drift que ningún script detecta

El validador ve rutas. Estas cuatro cosas solo las ve una persona leyendo:

1. **Afirmaciones numéricas.** "14 patrones", "5 aplicaciones", "tres scripts". Contá los archivos reales.
   Es el tipo de afirmación que envejece sin que nadie lo note.
2. **Referencias a secciones ajenas.** "ver §2 de tal documento" — abrí el documento y confirmá que §2
   trata de lo que le atribuís. Una cita a la sección equivocada es peor que ninguna cita: manda al
   lector a algo irrelevante y le hace perder la confianza en el resto.
3. **Atribuciones de estructura.** "la estructura que define tal README" — abrí ese README y confirmá que
   efectivamente la define. Si no, o lo agregás ahí o cambiás la atribución.
4. **Capacidades prometidas.** Si un doc dice que existe `foo.sh` en ambos sabores, verificá que los dos
   existan. Si dice que un script valida X, leé el script y confirmá que valida X.

## Paso 3 — Qué hacer con lo que encontraste

**Si el código y la doc se contradicen: el código manda.** La doc se corrige, no el código —salvo que la
doc describa la intención correcta y el código tenga el bug, caso en el que es un hallazgo, no un drift.
Distinguí los dos antes de "arreglar" nada.

Reportá cada discrepancia con archivo:línea y qué dice cada lado. Una lista de discrepancias concretas es
accionable; "la documentación está desactualizada" no.

## Cuándo NO usar esta skill

Si el proyecto todavía no tiene documentación que cite rutas de archivo, no hay nada que validar. El
validador es útil desde el momento en que un doc empieza a afirmar cosas concretas sobre el código, no
antes.

## Checklist

- [ ] Corrí el validador y el resultado es 0 citas rotas (o entiendo por qué las que quedan son
      placeholders legítimos).
- [ ] Verifiqué las afirmaciones numéricas contra el filesystem real.
- [ ] Abrí cada sección citada y confirmé que trata del tema que se le atribuye.
- [ ] Confirmé que cada capacidad prometida existe de verdad.
- [ ] Reporté las discrepancias con archivo:línea, no en abstracto.

## Relacionado

- `docs/00_philosophy/doc-freshness-strategy.md` — la estrategia completa de frescura.
- `docs/03_architecture_patterns/ai-knowledge-base-verification.md`
- `docs/00_philosophy/multi-agent-doc-sync.md` — cuando varios agentes editan el mismo repo.
