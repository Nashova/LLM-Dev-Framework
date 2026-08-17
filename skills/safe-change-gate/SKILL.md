---
name: safe-change-gate
description: Recorrer el checklist de seguridad antes de un cambio riesgoso. Úsala ANTES de editar migraciones o el modelo de datos, control de acceso o permisos, scripts shell, configuración de CI/CD o de despliegue, archivos marcados como PROTEGIDOS, o cualquier cosa que corra contra un ambiente compartido. También antes de ejecutar por primera vez un script cuyo nombre suene inocuo ("setup", "seed", "reset", "limpieza") contra algo que no sea 100% local y descartable.
---

# Puerta de seguridad antes de un cambio riesgoso

Cada ítem de aquí nació de un incidente real. La pregunta correcta hecha **antes** de actuar evita una
clase entera de error; la misma pregunta después es un postmortem.

## Primero: ¿esto es un cambio riesgoso?

Sí, si toca alguno de estos:

| Área | Por qué |
|---|---|
| Esquema de datos / migraciones | Un `sync` automático o un script ad-hoc genera drift silencioso |
| Control de acceso / permisos | Un cambio que funciona para tu rol puede romper otros |
| Scripts shell | Un CRLF rompe un container Linux sin dar un error legible |
| CI/CD, despliegue, config por ambiente | El drift rama-vs-rama no se ve en el código |
| Archivos PROTEGIDOS en `architecture.md` | Se extienden, no se modifican |
| Cualquier cosa contra un ambiente compartido | El error no es solo tuyo |

Si no toca ninguno: no necesitas esta skill, seguí adelante.

## El checklist

### Datos y esquema
- [ ] ¿El cambio de esquema va en una **migración formal**? Nunca un script ad-hoc, nunca "sync
      automático" del ORM en producción.
- [ ] Si el proyecto atraviesa ambientes greenfield y legacy a la vez, ¿la migración es **tolerante**
      (idempotente, no asume estado previo)?
- [ ] ¿Algún endpoint devuelve un objeto del ORM después del `commit()`? Sus relaciones diferidas ya
      expiraron — serializa antes, o recarga.

### Control de acceso
- [ ] ¿Verificaste que los roles **existentes** siguen funcionando para TODOS los roles, no solo el que
      estás probando?
- [ ] ¿Las comparaciones de rol son **por nivel** (`role.level >= requerido`) y no por nombre en string?
      Un rol se renombra y toda comparación por string se rompe en silencio.

### Scripts y line endings
- [ ] ¿El archivo `.sh` va a correr en Linux/container? Entonces **LF**, aunque lo edites en Windows.
      `.gitattributes` debe forzarlo y `safety-check` debe atraparlo.
- [ ] ¿El script nuevo tiene el bit de ejecución (`100755`)? En `100644` falla en un clon nuevo.

### Configuración por ambiente
- [ ] ¿Alguien propuso "compilar/procesar esto una sola vez y reusarlo en los N ambientes"? Confirmá
      **primero** si la configuración por ambiente vive en runtime o está horneada en el artefacto de
      build. Si está horneada, esa optimización rompe los otros ambientes en silencio.
- [ ] ¿El gap podría existir solo en el pipeline y no en el código? Comparar el pipeline de las 3 ramas,
      no solo leer la aplicación.

### Acciones destructivas
- [ ] ¿La acción borra datos, sobrescribe algo en producción, o rota una credencial compartida? Quien la
      ejecuta debe entender **exactamente qué se va a perder**, y no debe poder dispararla por accidente.
- [ ] ¿Vas a correr por primera vez un script que suena inocuo contra algo que no sea 100% local?
      **Leé qué hace realmente.** El nombre no es garantía: una tarea llamada "test setup" resultó hacer
      `DROP DATABASE` contra una conexión que en dos de tres ambientes no apuntaba a una base de test.

### Secretos
- [ ] ¿Estás por poner un valor real en un archivo trackeado, "solo por ahora"? No hay "lo saco después":
      una vez pusheado, queda en el historial para siempre aunque un commit posterior lo corrija.
- [ ] ¿El secreto se lee en runtime desde un archivo gitignored, y falla con error explícito si falta?

### Documentación en el mismo commit
- [ ] ¿El cambio agrega/modifica una regla de negocio, una decisión operativa, o un archivo protegido?
      Actualizá la doc correspondiente **en el mismo commit**.
- [ ] Si el pre-commit avisa que tocaste algo riesgoso sin tocar ninguna doc, no ignores el aviso sin
      pensarlo dos segundos.

## Verificación mecánica

```bash
bash scripts/safety-check.sh     # o: powershell -File scripts/safety-check.ps1
```

Atrapa line endings, sintaxis y el aviso de doc-viva desincronizada. **No sustituye al checklist** — el
script ve lo mecánico, el checklist ve lo que requiere criterio.

## Relacionado

- `docs/03_architecture_patterns/destructive-action-confirmation.md`
- `docs/03_architecture_patterns/tolerant-migrations.md`
- `docs/03_architecture_patterns/branch-per-environment-config.md`
- `docs/03_architecture_patterns/rbac-cascade.md`
- `docs/03_architecture_patterns/secrets-management.md`
- `skills/incident-capture/SKILL.md` — cuando el checklist llega tarde y algo ya se rompió.
