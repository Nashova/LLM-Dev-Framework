# Contribuir

Gracias por querer mejorar el framework. Es un proyecto personal mantenido por una sola persona: las respuestas no tienen un plazo garantizado, pero toda propuesta con evidencia se lee y se agradece.

## Qué aporta más valor

1. **Un patrón con evidencia**: un incidente real, su causa raíz y la regla que lo evita. Sin incidente no hay patrón — por qué funciona así está en [`incident-log-pattern.md`](docs/03_architecture_patterns/incident-log-pattern.md).
2. **Correcciones de scripts**: un fallo reproducible, con la salida completa, el sistema operativo y la versión de PowerShell o Bash.
3. **Traducciones**: la documentación está en español. Las traducciones al inglés (empezando por skills y patrones) son bienvenidas.
4. Erratas, enlaces rotos y aclaraciones.

## Antes de abrir un pull request

Corre lo mismo que corre la [integración continua](.github/workflows/ci.yml):

```bash
bash scripts/safety-check.sh
bash scripts/validate-knowledge-base.sh
python3 .github/scripts/check-links.py
```

Si tocaste un `.ps1`, comprueba también en Windows PowerShell 5.1:

```powershell
powershell -File scripts\safety-check.ps1
powershell -File scripts\validate-knowledge-base.ps1
```

## Reglas del repo (no son estéticas)

- **Los `.ps1` se escriben en ASCII puro**, sin acentos ni guiones largos: PowerShell 5.1 lee un archivo sin BOM como CP1252 y un `—` termina una cadena antes de tiempo. Razón completa en [`scripts/README.md`](scripts/README.md).
- **Los `.sh` usan LF** (lo fuerza [`.gitattributes`](.gitattributes)).
- **Cada script existe en ambos sabores** (`.ps1` y `.sh`) con el mismo comportamiento. La CI falla si falta un gemelo.
- **Anonimización**: ningún nombre de cliente, empresa, sistema interno, host, IP, correo ni identificador. Si dudas, aplica la skill [`pre-publication-audit`](skills/pre-publication-audit/SKILL.md).
- **Un patrón declara su alcance en la primera línea**, y las afirmaciones técnicas se apoyan en citas `archivo:línea` que el validador pueda comprobar.
- **Todo cambio de comportamiento se anota en [`CHANGELOG.md`](CHANGELOG.md)** bajo «No liberado».

## Flujo de trabajo

1. Haz un fork y crea una rama con nombre descriptivo.
2. Haz cambios pequeños y enfocados: un pull request, una idea.
3. Abre el pull request; la plantilla incluye la lista de verificación.

Al contribuir aceptas que tu aportación se publica bajo la [licencia MIT](LICENSE) del proyecto.
