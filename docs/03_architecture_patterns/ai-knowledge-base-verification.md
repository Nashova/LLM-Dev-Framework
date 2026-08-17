# Patron: Verificacion Automatizada de la Base de Conocimiento (Anti-Drift)

## El Problema
La documentacion tecnica tradicional sufre de obsolescencia acelerada ("drift"). Cuando los desarrolladores o IAs refactorizan rutas de archivos, renuevan endpoints o mueven modelos, la documentacion queda desfasada. Un LLM que lee documentacion desactualizada tomara decisiones basadas en mentiras ("alucinacion inducida por documentacion obsoleta").

## El Principio
> **Toda afirmacion tecnica en la base de conocimiento para IAs debe ser verificable mediante citas `archivo:linea` reales que se comprueben automaticamente en CI o via scripts.**

## La Solucion

### 1. Convencion de Citas Vivas
En los documentos de `docs/AI_Knowledge_Base/`:
- Solo usar backticks para rutas reales (ejemplo): `` `app/models/user.rb:45` `` o `` `src/app/services/auth.service.ts` ``.
- Los nombres conceptuales sueltos van sin backticks o sin slashes (`User`, `AuthService`).
- Elementos propuestos que aun no existen se marcan explicitamente con `(nuevo)` o `(propuesto)`.

### 2. Soporte para Codigo en Ramas No Promovidas
Cuando un desarrollo existe en `development` o `staging` pero no en `main`, el encabezado Markdown debe declarar el contexto de rama:
```markdown
### Integracion del Servicio (rama `development`)
El proxy reside en `app/services/proxy_service.rb:12`. (ejemplo)
```
El script validador (`validate-knowledge-base.ps1` / `.sh`) utiliza `git cat-file -e "${branch}:${path}"` para verificar la existencia del archivo en esa rama sin necesidad de cambiar de checkout.

### 3. Integracion en el Flujo de Trabajo
1. El script `validate-knowledge-base.ps1` se ejecuta antes de cualquier release o PR.
2. Si una cita esta rota, el build falla y obliga a sincronizar la documentacion antes de continuar.
