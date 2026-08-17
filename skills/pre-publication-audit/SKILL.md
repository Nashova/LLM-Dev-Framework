---
name: pre-publication-audit
description: Auditar un repositorio antes de hacerlo público u open source, o antes de entregarlo a un cliente o tercero. Úsala cuando el usuario diga "vamos a publicar esto", "hazlo open source", "súbelo a GitHub público", "quiero compartir este repo", "revisa que no haya info de cliente", o cuando un repo privado con historial real esté por cambiar de audiencia.
---

# Auditar un repo antes de publicarlo

Publicar un repo que nació privado no es cambiar un switch de visibilidad: es exponer **todo su
historial** a una audiencia nueva. La mayoría de las fugas no están en el estado actual del código —
están en commits viejos, en nombres de archivo, y en detalles que parecían inocuos cuando el repo era
interno.

## Regla que gobierna todo lo demás

**Editar los archivos no borra nada del historial.** Si un nombre de cliente estuvo en un commit que ya
se pusheó, sigue ahí y es recuperable con `git log -p`, por más que el archivo actual esté limpio. Decidí
qué hacer con el historial **antes** de publicar, no después.

## Fase 1 — Barrido de confidencialidad

Buscá en **todos los archivos y todos los commits**, no solo en el árbol actual:

```bash
git grep -i -E '<patron>' $(git rev-list --all)
```

Qué buscar, en orden de gravedad:

1. **Secretos**: tokens, PATs, passwords, connection strings, claves privadas. Si encontrás uno,
   **rotalo** — es lo único que invalida de verdad lo que ya quedó expuesto.
2. **Nombres propios**: clientes, empresas, sistemas internos, personas, correos, handles.
3. **Giro del negocio**: el sector combinado con el stack y la topología es huella digital suficiente
   para identificar a una empresa, aunque no aparezca su nombre.
4. **Infraestructura**: IPs, hostnames, URLs internas, nombres de contenedores, organizaciones de
   Azure DevOps/GitLab, IDs de tickets, rutas absolutas de máquinas reales.
5. **Esquema interno**: nombres de tablas y columnas, variables de entorno específicas, nombres de
   archivos de configuración internos.
6. **Detalle operativo explotable**: esto es lo que más se pasa por alto. Un gap de configuración de
   producción sin remediar, una tarea destructiva que apunta a datos reales, credenciales horneadas en un
   artefacto de build. Documentar el incidente es valioso; publicar **la vulnerabilidad vigente de un
   sistema real** no lo es.

No olvides los lugares donde nadie busca: nombres de archivo, mensajes de commit, `.gitattributes`,
comentarios de encabezado en scripts, y los `_source.md` o notas de procedencia.

## Fase 2 — Anonimizar sin vaciar de contenido

El objetivo no es borrar la experiencia: es **conservar el mecanismo y tirar la huella digital**.

| Clase de dato a tirar | Con qué reemplazarlo |
|---|---|
| Nombre del sistema y de la empresa | La **forma** del sistema: "una consola administrativa interna" |
| Stack con versiones exactas | La **categoría**: "backend MVC + SPA + dos motores de reportes" |
| Sector o giro del negocio | El **atributo relevante**: "un sector con cumplimiento regulatorio" |
| Nombre real de tabla, columna o variable | Su **rol**: "una columna de ruta" |
| Topología exacta (cuántos repos, cuáles, qué tecnología cada uno) | El **orden de magnitud**: "media docena de aplicaciones independientes" |
| La vulnerabilidad vigente y sin remediar | La **regla generalizable** que sale de ella |

> **No uses los datos reales como ejemplo de qué anonimizar.** Suena obvio y es el error que cometimos al
> escribir esta misma skill: la tabla de arriba llevaba, en su primera versión, el stack y el sector
> textuales del cliente como columna de "qué tirar" — reintroduciendo en un repo público exactamente la
> huella digital que la skill sirve para eliminar. Lo detectó el barrido de la Fase 5 sobre el clon.
> Describí la **clase** de dato, nunca una instancia.

Renombrá también los **archivos** (`cliente-case-study.md` → `case-study-<forma-del-sistema>.md`) y barré
todas las referencias cruzadas: la mitad del trabajo está en las ~30 menciones repartidas en docs y
scripts, no en el archivo obvio.

## Fase 3 — Decidir qué hacer con el historial

Tres opciones, con costos muy distintos. **Es una decisión del dueño, no tuya.** Presentala explícitamente:

| Opción | Efecto | Costo |
|---|---|---|
| **Borrar y recrear el repo** | Es la única que garantiza que no quede nada | Hay que rehacerlo en la UI del proveedor; se pierden stars/forks/issues |
| **Reescribir el historial** (raíz huérfana o `git filter-repo`) + force-push | Limpia el historial visible | Rompe todo clon existente. En GitHub, **los commits viejos siguen accesibles por su SHA directo** hasta que su GC los recoja, lo que puede no pasar nunca sin pedirlo a soporte |
| **Solo limpiar el estado actual** | Rápido | Los datos siguen recuperables del historial para siempre |

Si eligen reescribir: **dejá un tag o rama de respaldo local** apuntando al historial viejo antes de
tocar nada, y avisá explícitamente que esas referencias locales no se deben pushear nunca.

## Fase 4 — Higiene de repo público

- [ ] `LICENSE` presente y coherente con lo que el repo redistribuye.
- [ ] **Contenido de terceros**: ¿hay algo vendorizado? Verificá su licencia. Si es MIT, mantené la
      atribución. Si la licencia no consta o no es OSS, **no lo redistribuyas** — enlazá al upstream y
      dejá que el usuario lo instale.
- [ ] `.gitignore` no excluye archivos que la documentación exige trackear (plantillas de config,
      `*.template.*`).
- [ ] `README` no promete archivos, scripts o capacidades que no existen.
- [ ] Los conteos y afirmaciones numéricas coinciden con el filesystem real (ver `doc-drift-check`).

## Fase 5 — Verificar desde afuera

No confíes en que el push salió bien: **cloná el remoto en un directorio limpio** y corré el barrido de la
Fase 1 sobre el clon. Es la única comprobación que refleja lo que ve un tercero.

```bash
git clone <url> /tmp/verificacion && cd /tmp/verificacion
git grep -i -E '<patron>' $(git rev-list --all)   # debe devolver 0 resultados
```

## Checklist

- [ ] Barrido sobre **todos** los commits, no solo el árbol actual.
- [ ] Secretos encontrados: **rotados**, no solo borrados.
- [ ] Anonimización conserva el mecanismo y elimina la huella.
- [ ] Archivos renombrados y todas las referencias cruzadas barridas.
- [ ] La decisión sobre el historial la tomó el dueño, informado del costo real de cada opción.
- [ ] Respaldo local del historial viejo, con aviso de no pushearlo.
- [ ] Licencias de terceros verificadas antes de redistribuir.
- [ ] Verificado sobre un **clon fresco** del remoto.

## Relacionado

- `docs/03_architecture_patterns/secrets-management.md` — por qué rotar le gana a reescribir el historial.
- `skills/doc-drift-check/SKILL.md` — para la Fase 4.
- `examples/` — los tres casos de estudio del framework son el resultado de aplicar esta skill.
