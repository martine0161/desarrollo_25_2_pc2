# Bitácora Sprint 1 - Clasificación de Fallos

Enfocado en análisis y bitácora

### Objetivos

Establecer Makefile con target para analizar resolución de DNS e implementar script `classify_failures.sh` base para analizar y clasificar fallos en resolución de DNS.

### puntos a desarrollar
- Implementar script `classify_failures.sh` base para analizar y clasificar fallos frecuentes en resolución de DNS
- Configuración de variables de entorno en `Makefile`.
- Auto mapeo de target para help y llamado a ejecución de script `classify_failures.sh` desde `Makefile`.

### Creación script classify_failures.sh

se implemento dos funciones `dns_check` y `show_report`, los resultados comunes a mapear son, SERVICE_OK, DNS_FAIL, TIMEOUT, CONN_REFUSED, FIREWALL_REJECT y UNKNOWN para otro tipo de errores.

- *ns_check:* utiliza `nc` para realizar una prueba de conectividad TCP, analizando el resultado para generar un reporte del resultado de la prueba.
- *show_report:* Muestra el reporte generado por `ns_check`

Opciones disponibles para el uso del script:
```bash
Uso: ./classify_failures.sh <comando> [parámetros]

Comandos disponibles:
  dns_check <host> <puerto> [out_dir]  - Resuelve DNS de host ingresado
  show_report [out_dir]                - Muestra el reporte generado por dns_check
  help                                 - Muestra esta ayuda
```

### Creación Makefile

Se implementaron targets básicos para la ejecución del script `classify_failures.sh`.

```bash
Make targets:
  help                    Muestra los targets disponibles para el proyecto
  dns_check               Verifica resolución de DNS generando bitacora de resultados
  show_report             Muestra reporte de resultados para dns_check
```

### Pruebas

Para ejecutar pruebas, ejecutar:

```bash
make dns_check HOST=<host> PORT=<port>
```

Ejemplo de salida:

```bash
$ make dns_check HOST=google.com PORT=8080
Prueba de resolución de DNS
google.com 8080
=====================================
Result: TIMEOUT

$ make dns_check HOST=google.com PORT=80
Prueba de resolución de DNS
google.com 80
=====================================
Result: SERVICE_OK
```

Ejemplo de reporte consolidado:

```bash
$ make show_report 
Reporte de resultados de dns_check
Reporte de monitoreo:
====================
timestamp           host                          port   cause
30-09-25 17:27:38   db-beta.imaxempresarial.com   9543   TIMEOUT
30-09-25 17:28:11   db-beta.imaxempresarial.com   9453   TIMEOUT
30-09-25 17:28:27   db-beta.imaxempresarial.com   80     TIMEOUT
30-09-25 17:28:11   db-beta.imaxempresarial.com   9453   TIMEOUT
30-09-25 17:28:27   db-beta.imaxempresarial.com   80     TIMEOUT
30-09-25 17:29:22   db-beta.imaxempresarial.com   9753   TIMEOUT
30-09-25 17:29:51   db-beta.imaxempresarial.com   9753   CONN_REFUSED
30-09-25 17:30:02   db-beta.imaxempresarial.com   9753   CONN_REFUSED
30-09-25 17:30:15   db-beta.imaxempresarial.com   9753   CONN_REFUSED
30-09-25 17:30:30   db-beta.imaxempresarial.com   9453   SERVICE_OK
30-09-25 18:28:48   db-beta.imaxempresarial.com   80     CONN_REFUSED
30-09-25 18:29:36   db-beta.imaxempresarial.com   80     CONN_REFUSED
30-09-25 18:30:16   google.com                    8080   TIMEOUT
30-09-25 18:30:55   google.com                    80     SERVICE_OK
```