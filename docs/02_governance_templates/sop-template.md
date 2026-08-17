# SOP: [Nombre del Procedimiento Estandarizado]

| Metadato | Valor |
|---|---|
| **Codigo SOP** | SOP-[AREA]-[NUMERO] |
| **Version** | 1.0 |
| **Fecha de Aprobacion** | YYYY-MM-DD |
| **Ambito / Modulo** | [Backend / Frontend / DevOps / Base de Datos] |
| **Responsable** | [Rol o Equipo] |

---

## 1. Proposito
Descripcion de alto nivel del objetivo de este procedimiento y en que escenarios exactos debe ejecutarse.

## 2. Precondiciones y Validaciones Previas
- [ ] Validacion 1 (ej. Verificar que no hay transacciones activas).
- [ ] Validacion 2 (ej. Confirmar que el backup de BD esta disponible).

## 3. Procedimiento Paso a Paso

### Paso 1: [Nombre del Paso]
Explicacion y comandos exactos:
```bash
# Comando a ejecutar
comando --parametro valor
```

### Paso 2: [Nombre del Paso]
```bash
# Comando de verificacion
comando_verificacion
```

## 4. Plan de Rollback / Contingencia
Que hacer inmediatamente si el procedimiento falla en algun paso intermedio para regresar el sistema a un estado seguro:
```bash
# Rollback
comando_rollback
```

## 5. Criterios de Verificacion Exitosa
Como saber con evidencia cuantificable que el procedimiento concluyo correctamente.
