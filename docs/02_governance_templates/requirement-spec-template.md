# REQ-YYYY-NNN: [Titulo del Requerimiento de Negocio]

| Metadato | Valor |
|---|---|
| **ID Requerimiento** | REQ-YYYY-NNN |
| **Proyecto Asociado** | PROY-YYYY-NNN (si aplica) |
| **Fecha de Solicitud** | YYYY-MM-DD |
| **Solicitante / Stakeholder** | [Area de Negocio / Cliente] |
| **Prioridad Negocio** | [Must Have / Should Have / Could Have / Won't Have] |
| **Estado** | [Borrador / En Revision / Aprobado / Promovido a Proyecto] |

---

## 1. Problema de Negocio / Oportunidad
Descripcion clara de la necesidad desde la perspectiva del usuario final (que dolor operativo resuelve o que valor genera).

## 2. Alcance (In Scope / Out of Scope)
* **Dentro del Alcance:**
  * Requerimiento funcional 1.
  * Requerimiento funcional 2.
* **Fuera del Alcance:**
  * Elementos explícitamente excluidos para esta fase.

## 3. Requerimientos Funcionales Detallados (RF)
* **RF-01:** El sistema debe permitir...
* **RF-02:** Al presionar..., el sistema validara...

## 4. Criterios de Aceptacion (Gherkin / Given-When-Then)
```gherkin
Scenario: Usuario realiza accion exitosa
  Given que el usuario tiene el rol "Operador"
  When envia el formulario con datos validos
  Then el sistema responde con codigo 200 y persiste el registro
```

## 5. Riesgos Conocidos y Preguntas Abiertas
* **Riesgo 1:** [Descripcion del riesgo y mitigacion]
* **Pregunta Abierta 1:** [Decision pendiente que requiere feedback del usuario]
