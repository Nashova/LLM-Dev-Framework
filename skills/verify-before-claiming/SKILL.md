---
name: verify-before-claiming
description: Verificar contra el estado real antes de afirmar que algo existe, que no existe, o que está en uso. Úsala ANTES de responder "eso no existe", "ya está implementado", "esa función se llama X", "esto no se usa", o antes de construir sobre algo recordado de una sesión anterior, de tu memoria persistente, del resumen de otro agente o de una búsqueda web. También cuando vayas a heredar una asunción del código existente (un nombre de columna, un endpoint de terceros, una ruta de red) sin haberla comprobado tú.
---

# Verificar antes de afirmar

Esta skill existe porque **la clase de error más caro de un LLM no es escribir código malo — es afirmar
con confianza algo falso sobre el estado del sistema**, y que un humano tome una decisión sobre esa
afirmación. Los tres casos de estudio del framework tienen incidentes de esta familia, con mecanismos
distintos.

## Las cinco falsas certezas, y cómo se rompe cada una

### 1. "Eso no existe en el proyecto"

Leer el disco no es leer el proyecto. Si el proyecto promueve por ramas (`development → staging → main`),
la rama activa **no tiene todo**. Un trabajo completo puede vivir en otra rama, o en otro repo del
ecosistema.

```bash
git show <rama>:<ruta>           # ¿existe el archivo en esa rama?
git log <rama> --oneline -- <ruta>
git branch -a                    # ¿qué ramas hay, incluidas las remotas?
```

En un repo raíz que orquesta varios repos independientes, los directorios de las aplicaciones aparecen
**vacíos** en cualquier worktree que no sea el principal. "La carpeta está vacía" no significa "no hay
código": significa que estás mirando un worktree.

### 2. "Está en el código, entonces se usa"

Código presente, conectado y funcional **no es** funcionalidad en uso operativo real. Un método de login
alternativo, un flujo secundario, un botón: pueden estar completos y no formar parte del uso real del
negocio. Esto **no se deriva leyendo el código** — solo lo confirma quien opera el sistema.

> Si vas a **construir sobre** algo porque "ya está ahí y funciona", pregunta antes. Si solo lo vas a
> mencionar, no hace falta.

### 3. "Mi memoria dice que ya se corrigió"

Una entrada de memoria persistente (o el resumen de una sesión anterior, o tu propio turno previo) es
**una fotografía de lo que era cierto cuando se escribió**. El código cambia; los recuerdos no se
actualizan solos. En un caso real, la memoria decía "ya corregí este error de worktree" y esa afirmación,
sin re-verificar, llevó a repetir exactamente el mismo error.

Antes de actuar sobre algo recordado: greppea el nombre, confirma que el archivo existe, lee la línea.

### 4. "El esquema/la API externa funciona como dice la documentación"

Una asunción heredada sobre un sistema que no controlas (una columna de base de datos, un campo de una
API de terceros, una ruta de red) puede haber sido falsa **desde que se escribió el código**, y nadie lo
nota si solo hay un lugar que la consume y ningún test.

Verifica contra el sistema real, o pregunta a quien conoce el esquema. Si no puedes verificar, **dilo
explícitamente** en vez de presentarlo como hecho.

### 5. "El resumen de la búsqueda dice que el repo tiene X"

Un resumen de búsqueda web puede enumerar archivos, funciones o nombres que **no existen** en el
repositorio real. Antes de adoptar o vendorizar contenido de terceros, verifica contra el árbol de
archivos real (una API de listado, un clon), no contra un resumen de texto.

## Procedimiento

1. Identifica la afirmación que estás por hacer y clasifícala en una de las cinco de arriba.
2. Corre la verificación concreta que le corresponde. **Una sola vez es suficiente; cero no lo es.**
3. Si la verificación es imposible en tu entorno (no tienes acceso a la BD, al servidor, al sistema
   externo), **no rellenes el hueco con una inferencia plausible**. Reporta: "no pude verificar X; lo que
   sí sé es Y; ¿me lo confirmas?".
4. Si un límite del entorno te bloquea (un clasificador de seguridad, un permiso faltante), **no busques
   un rodeo técnico**. Explica qué intentaste y por qué, y deja que la persona decida.

## Antipatrones

- Presentar una inferencia como un hecho verificado, aunque la inferencia sea razonable.
- Decir "parece que no existe" y seguir adelante como si fuera un hecho establecido.
- Verificar una sola de las cinco vías y dar por cerrado el resto (ej. confirmar que el archivo existe en
  disco, pero no que la rama activa sea la relevante).
- Re-verificar cincuenta veces lo mismo por inseguridad. Una verificación concreta cierra el punto.

## Checklist

- [ ] ¿La afirmación es sobre existencia? → verificado en la rama correcta, no solo en disco.
- [ ] ¿Es sobre uso operativo? → confirmado con una persona, no inferido del código.
- [ ] ¿Viene de memoria o de un turno anterior? → re-verificado contra el estado actual.
- [ ] ¿Depende de un sistema externo? → comprobado contra el sistema, o marcado como no verificado.
- [ ] ¿Viene de un resumen de búsqueda? → comprobado contra el árbol real.
- [ ] Si no pude verificar, ¿lo dije explícitamente en vez de omitirlo?

## Relacionado

- `docs/00_philosophy/collaboration-style.md` §2 (verificar antes de recomendar desde memoria) y §8
  (código presente ≠ código en uso).
- `docs/03_architecture_patterns/verify-external-assumptions.md`
- `docs/03_architecture_patterns/multi-repo-orchestrator.md` (asimetría de worktrees)
- `docs/00_philosophy/persistent-memory-pattern.md`
