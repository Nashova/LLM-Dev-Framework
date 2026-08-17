# Arquitectura — [Nombre del Proyecto]

> Copiar a (template) `Docs/03_governance_and_guidelines/architecture.md`. A diferencia de `change-safety.md`, este documento SÍ conviene escribirlo desde el día 1, aunque sea con la estructura planeada en vez de la real — se corrige a medida que el proyecto se aparta del plan original (siempre pasa, no es un fracaso).

## 1. Stack

<!-- TODO: lenguaje/framework de backend, frontend, base de datos, infraestructura de despliegue (contenedores, serverless, VM). Versiones EXACTAS de las dependencias que importan (no "React", sino "React 18.3.1") si alguna vez hubo o se anticipa un problema de compatibilidad de versión. -->

## 2. Versiones ancladas (pinned) y por qué

<!-- TODO: cualquier dependencia que NO se puede actualizar sin coordinación explícita, con la razón. Ejemplo real: una librería de tunneling SSH anclada a una versión específica porque las versiones más nuevas rompían la compatibilidad con el sistema operativo del servidor de producción -- ese tipo de restricción es invisible en el código y solo vive acá. -->

| Dependencia | Versión anclada | Por qué |
|---|---|---|
| | | |

## 3. Archivos protegidos

Archivos donde un LLM (o cualquiera trabajando rápido) **solo debe agregar líneas nuevas, nunca modificar las existentes**, salvo que el cambio sea intencional y revisado explícitamente. Típicamente: el punto de entrada de la aplicación, el registro central de rutas/módulos, el archivo de configuración de seguridad/autenticación, el archivo de estilos/tema global.

<!-- TODO: lista real del proyecto. El criterio para agregar un archivo aquí: ¿un cambio "de paso" en este archivo, hecho para resolver un problema no relacionado, podría romper silenciosamente algo que no se está mirando en ese momento? Si sí, es protegido. -->

| Archivo | Por qué está protegido |
|---|---|
| | |

## 4. Inventario de módulos / rutas / componentes principales

<!-- TODO: tabla o lista de los módulos/routers/componentes principales del sistema, con una línea de descripción cada uno y un link al documento técnico correspondiente si existe. Mantener esto actualizado es barato (una línea por módulo nuevo) y el retorno es alto -- es lo primero que un LLM nuevo en el proyecto necesita para orientarse sin leer todo el código. -->

## 5. Decisiones de arquitectura no obvias

<!-- TODO: cualquier decisión de diseño que alguien nuevo (humano o LLM) podría "corregir" por accidente porque parece un error, pero es intencional. Ejemplo real: un módulo podía asignarse a un usuario sin que su sección padre estuviera también asignada -- parecía un bug de la cascada de permisos, pero era una feature deliberada. Documentarlo evita que alguien lo "arregle" rompiendo el comportamiento esperado. -->
