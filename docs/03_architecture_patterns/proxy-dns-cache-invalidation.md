# Patrón: invalidar el caché DNS del proxy tras reconstruir un contenedor

Aplica a cualquier arquitectura Docker Compose donde un proxy reverso (Nginx, Traefik, similar) enruta tráfico hacia un contenedor backend/frontend por nombre de servicio.

## El problema

Al reconstruir un contenedor (`docker compose build backend` + recreate), Docker le asigna una IP interna nueva. El proxy reverso, que resolvió el nombre del servicio a la IP vieja al arrancar, mantiene esa IP en su caché DNS interno — el resultado inmediato es un `502 Bad Gateway`, que un LLM (o un humano apurado) interpreta con facilidad como "rompí el código de la aplicación" cuando la causa real no tiene nada que ver con el código que se acaba de tocar.

## El patrón: todo rebuild de un nodo va seguido de un reinicio del proxy

En cualquier flujo de despliegue (automatizado o manual), reconstruir o recrear un contenedor backend/frontend DEBE ir seguido de un reinicio explícito del contenedor proxy — nunca asumir que el proxy va a notar el cambio de IP solo.

## Regla práctica

- Después de recrear o reiniciar el contenedor subyacente, reiniciar explícitamente el proxy (`docker restart <proxy-container>` o el equivalente del stack) para forzar la limpieza de su caché DNS.
- Un `502` inmediatamente después de un deploy no es evidencia de un bug de código — es la primera hipótesis a descartar reiniciando el proxy, antes de invertir tiempo debuggeando la aplicación.
- Encapsular esta secuencia en el script de deploy/ship del proyecto en vez de confiar en que quien despliega se acuerde del paso manual — ver `docs/00_philosophy/why-scripts-not-instructions.md`.

## Ejemplo real (caso A)

Este incidente se repitió lo suficiente en el caso A como para convertirse en una entrada numerada del catálogo de incidentes reales del proyecto (`change-safety.md`) y, después, en un paso automático dentro del script de despliegue — el reinicio del proxy dejó de depender de que alguien lo recordara.

## Checklist corto

- [ ] ¿El script de deploy reinicia el proxy automáticamente después de recrear cualquier contenedor que enrute a través de él?
- [ ] ¿La primera reacción documentada ante un `502` post-deploy es "reiniciar el proxy", no "revisar el código recién cambiado"?
