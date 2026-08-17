---
name: ship-changes
description: Entregar cambios usando el pipeline del proyecto en vez de git a mano. Úsala cuando el usuario diga "commitea", "sube esto", "haz push", "despliega", "crea el PR", "ship it" o "ya terminé". También cuando estés por correr git add / git commit / git push manualmente en un proyecto que tiene scripts/ship.
---

# Entregar con el pipeline, no con git a mano

`ship` colapsa el flujo completo en un comando: **safety-check → commit → (deploy opcional) → push →
crear/actualizar PR**. La razón de existir no es ahorrar teclas: es que el safety-check corra **siempre**,
incluso cuando el que entrega va apurado.

```bash
bash scripts/ship.sh -m "mensaje" [--deploy] [--no-pr] [--base main]
# Windows:
powershell -File scripts/ship.ps1 -Message "mensaje" [-Deploy] [-NoPr] [-Base main]
```

## Antes de invocarlo

1. **Corré `safe-change-gate`** si el cambio toca algo riesgoso. `ship` corre los chequeos mecánicos, no
   el criterio.
2. **Revisá qué se va a incluir.** `ship` hace `git add -A`. Corré `git status` y mirá la lista: un
   archivo de secretos, un dump de base, un `.env`, un binario de 200 MB o un archivo temporal entran
   igual de fácil que el código que querías subir.
3. **Escribí el mensaje de commit primero.** La primera línea se convierte en el título del PR.

## Reglas de despliegue por ambiente

**Una autorización de alcance no se extiende automáticamente a otro.** Que el usuario haya aprobado un
push a staging no autoriza un push a producción, ni ahora ni en el mismo turno.

Lo habitual, y lo que hay que respetar salvo que el proyecto diga otra cosa:

| Ambiente | Regla |
|---|---|
| Local / desarrollo | Push directo |
| Staging | Push directo (compartido con el equipo, riesgo real bajo) |
| **Producción / el que ve el cliente** | **Siempre** PR/MR aprobado a mano por una persona, incluso para cambios ya probados en staging |

Si `--deploy` apunta a producción y nadie te lo pidió explícitamente **en este turno**, no lo pases.

## Cuando falla

- **`safety-check` falla** → no lo puentees, no uses `--no-verify`. Arreglá lo que reportó. El chequeo
  existe porque cada uno de sus ítems atrapó una regresión real.
- **Falta `_config.sh`/`_config.ps1`** → copiá la plantilla `_config.template.*` y llená las variables.
- **El PR no se crea** → revisá que el proveedor de git se detecte bien y que el token esté en el archivo
  de secretos local. Con Bitbucket, el framework **no** implementa la creación de PR y falla
  explícitamente: creá el PR a mano, no asumas que se creó.
- **Nada que commitear** → `ship` sale en 0 con el árbol limpio. Si esperabas cambios, algo no se guardó.

## Antipatrones

- `git commit` a mano "porque es un cambio chico". El safety-check no distingue tamaño, y las regresiones
  de line-endings y sintaxis tampoco.
- Pasar `--deploy` por costumbre.
- Commitear con un mensaje genérico (`fix`, `wip`, `cambios`) — ese mensaje se convierte en el título del
  PR y en el registro que alguien va a leer en seis meses.
- Correr `ship` con trabajo de otra persona en el árbol: `git add -A` se lo lleva todo.

## Checklist

- [ ] `git status` revisado; nada inesperado ni sensible en la lista.
- [ ] Mensaje de commit escrito, con primera línea que sirve de título.
- [ ] `safe-change-gate` recorrido si el cambio es riesgoso.
- [ ] Si toca producción, hay autorización explícita **de este turno**.
- [ ] Después de correr: confirmé que el PR realmente existe (no que el script dijo que sí).

## Relacionado

- `docs/00_philosophy/collaboration-style.md` §6 — acciones reversibles vs irreversibles.
- `docs/03_architecture_patterns/secrets-management.md`
- `scripts/git-provider-pr.ps1` / `.sh` — detección de proveedor y API REST.
