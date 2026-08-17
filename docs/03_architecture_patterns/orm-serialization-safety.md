# ORM Serialization Safety (DetachedInstanceError)

## El Problema Clásico con LLMs
En frameworks como FastAPI con SQLAlchemy (Python), los LLMs a menudo escriben endpoints que modifican la BD y retornan el objeto modificado de esta manera:
```python
db.delete(item)
db.commit()
return item # ¡ERROR 500!
```
Debido a que las relaciones (lazy loading) expiran tras el `commit()`, FastAPI intenta serializar el objeto y lanza un `DetachedInstanceError`.

## El Patrón "Safe Return"
1. **Refresh Explícito:** Si la respuesta DEBE incluir el esquema completo del objeto, el LLM debe ejecutar `db.refresh(item)` antes de retornarlo, O bien hacer el mapeo al Pydantic DTO *antes* del commit.
2. **Mensajes Planos para DELETE:** Los endpoints de borrado nunca deben retornar el objeto borrado. Deben retornar un diccionario simple: `{"message": "Elemento eliminado exitosamente"}`.

## Reglas para inyectar en el Prompt del Agente
- En rutas `DELETE`, o tras confirmar cambios en BD (`commit`), NO devuelvas el esquema del objeto si posee relaciones `lazy` sin haberlo preparado antes.
- Para operaciones de borrado, retorna un diccionario estático.
