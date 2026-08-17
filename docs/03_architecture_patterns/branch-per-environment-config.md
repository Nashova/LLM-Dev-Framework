# Patrón: configuración por ambiente cuando la promoción es por rama, no por variable

Aplica a cualquier proyecto donde `development`/`staging`/`production` (o los ambientes que use el proyecto) se promueven moviendo código entre **ramas de Git**, en vez de (o además de) mediante variables de entorno de runtime. Es un tipo de drift distinto al que cubre `tolerant-migrations.md` (que es sobre el schema de datos) — este es sobre la propia definición de "qué configuración corre en cada ambiente".

## El problema de fondo

Cuando la config por ambiente vive en variables de entorno leídas en runtime, un mismo artefacto de build/imagen sirve para los 3 ambientes — solo cambia qué variables se le inyectan al arrancar. Pero varios frameworks de frontend (y algunos de backend) permiten, en cambio, **compilar la configuración dentro del artefacto** (archivos `environment.*.ts` de Angular, `.env` files empaquetados en el build en vez de leídos en runtime, constantes resueltas en tiempo de compilación). Cuando eso pasa, el artefacto de build YA NO es intercambiable entre ambientes — cada ambiente necesita su propio build, aunque el código fuente sea idéntico.

Esto es invisible leyendo solo la aplicación en abstracto — hay que abrir los archivos de configuración reales de cada ambiente y comparar.

## La trampa concreta: "compilar una sola vez y reusar en los 3 ambientes"

Es una optimización que suena obviamente correcta ("¿por qué compilar 3 veces si el código fuente es el mismo?") y es exactamente el tipo de sugerencia que un LLM (el que sea, con o sin contexto del proyecto) va a proponer si se le pide "optimiza este pipeline de CI/CD" sin que también se le dé el contexto de cómo vive la configuración por ambiente en ESE proyecto específico.

**Regla práctica, antes de aceptar CUALQUIER propuesta de "un solo build/proceso, reusado en N ambientes":**
1. Verificar explícitamente, contra el código real, si la configuración que cambia entre ambientes se lee en **runtime** (variable de entorno, archivo de config externo al artefacto) o si vive **horneada en el artefacto de build** (constantes compiladas, archivos de config empaquetados dentro del bundle/imagen).
2. Si vive horneada: la unificación real que vale la pena no es "un build para todos los ambientes" — es separar la etapa de *build* de la etapa de *deploy* dentro del pipeline (cada ambiente sigue necesitando su propio build con su propia config, pero el paso de desplegarlo puede unificarse/simplificarse).
3. Documentar la respuesta de (1) explícitamente en `architecture.md` — es exactamente el tipo de "decisión no obvia" que alguien (humano o LLM) va a intentar "optimizar" de nuevo más adelante sin saber que ya se evaluó.

## Drift entre ramas que no es drift de código

Cuando la promoción es por rama, hay una segunda clase de drift que no aparece en ningún diff de código de la aplicación: diferencias entre el **pipeline de CI/CD** de cada rama (qué variables inyecta, qué servicios enlaza, qué comandos corre) que sí se versiona junto con el código pero que a nadie se le ocurre revisar comparando ramas explícitamente. Un caso real: una variable de conexión a un servicio nuevo se agregó al pipeline de `development` y `staging` al integrar ese servicio, pero nunca se agregó al bloque de `production` — nada en el código de la aplicación lo revela, porque el código es idéntico en las 3 ramas; solo el archivo de pipeline difiere.

**Regla práctica:** cuando un proyecto usa este patrón de promoción por rama, correr una auditoría periódica de diff entre ramas — no solo del código de la aplicación, también de los archivos de pipeline/CI (`git diff origin/staging origin/main -- .gitlab-ci.yml` o equivalente) y de los archivos de configuración por ambiente. Si el proyecto tiene varios repos (ver `multi-repo-orchestrator.md`), esta auditoría se repite por cada repo — el drift de uno no predice el de otro. El resultado de esa auditoría es exactamente el tipo de hallazgo que va a (template) `Docs/03_governance_and_guidelines/change-safety.md` si ya causó un incidente, o a una entrada de riesgo abierto si se detectó antes de que causara uno.

## Checklist

- ¿La configuración que difiere entre ambientes se lee en runtime o se compila en el artefacto? → verificado y documentado en `architecture.md`, no asumido.
- ¿Alguien propuso "un solo build/proceso para todos los ambientes"? → confirmar el punto anterior antes de aceptarlo, aunque la propuesta venga de un LLM con buena reputación en general.
- ¿El pipeline de CI/CD difiere entre ramas de forma que no se ve en el código de la aplicación? → auditar explícitamente el archivo de pipeline de cada rama, no solo el código.
