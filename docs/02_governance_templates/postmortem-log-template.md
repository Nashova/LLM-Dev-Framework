# Postmortem & Fixes Log

Este documento mantiene un registro estructurado de todos los fallos criticos detectados en el sistema y como fueron resueltos por el equipo o los asistentes de IA, incluyendo la causa raiz tecnica y los procedimientos generados para evitar su recurrencia.

---

## [ID_SECUENCIAL]. [Titulo Descriptivo del Fallo / Fix]

* **Fecha:** YYYY-MM-DD
* **Agente / Autor:** [Nombre del Agente / Desarrollador]
* **Problema Detectado:** Descripcion concisa del sintoma observable o error en produccion/staging (que fallaba, bajo que condiciones y como se manifestaba).
* **Causa Raiz (Root Cause):** Explicacion tecnica detallada del por que ocurria la falla a nivel de codigo, concurrencia, base de datos o configuracion de infraestructura (sin culpar a librerias externas, explicando la brecha de asuncion).
* **Solucion Implementada:**
  1. Descripcion del cambio arquitectonico o logico.
  2. Archivos modificados: `ruta/al/archivo.ext:linea` con la justificacion tecnica de cada cambio.
  3. Pruebas de regresion agregadas (specs, tests unitarios o e2e).
* **Deuda Tecnica / SOPs generados:**
  - SOPs generados (ej. `SOP_Recovery.md`) o lineamientos agregados a `AGENT_GUIDE.md`.
  - Deuda tecnica registrada en `Technical_Debt_Log.md` si se requirio una solucion temporal.
