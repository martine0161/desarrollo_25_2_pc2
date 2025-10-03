
# Bitácora Sprint 2 - Generación de reportes

Enfocado en implementar reporte de resultados de resolución de DNS.

### Objetivos

Agregar script `generate_logbook.sh` encargado de generar reporte consolidado de pruebas realizados con script `classify_failures.sh`, se genera el reporte a partir de nc_result.csv generado en el análisis.

### puntos a desarrollar

- implementar script `generate_logbook.sh` para generar reporte de resultados de resolución de DNS a partir de los logs generados en el sprint 1.
- Agregar target en Makefile para ejecutar script `generate_logbook.sh`.

### Creación script generate_logbook.sh

Se implemento funciones especificas para generar un reporte consolidado de resultados en la pruebas de conexión con `nc`.

script `generate_logbook.sh` opciones para ejecución

```bash
Comando:
        ./generate_logbook.sh [OPCION] <archivo> <fecha> [host1 host2 ...]

OPCIONES:
  --report      Genera un reporte de conexión TCP filtrando por fecha y hosts opcionales.
  --help        Muestra este mensaje ayuda.

ARGUMENTOS OBLIGATORIOS:
  <archivo>     Ruta al archivo CSV que contiene los registros.
  <fecha>       Fecha para filtrar los registros en formato dd-mm-yy

ARGUMENTOS OPCIONALES:
  [host1 host2 ...]   Lista de hosts específicos a incluir en el reporte
```

  **--report**: genera el reporte a partir de un archivo csv donde se registran las pruebas de conexión hacia un host y puerto que quedan evidenciados en el archivo, indicando el tipo de falla registrado. Esto recibe como argumento la ruta del archivo de la cual se generara el reporte y la fecha, estos son argumentos obligatorios para la generación del reporte; también podemos agregar los host a filtrar en el reporte.


### Target agregado a Makefile

Se agrego el target `generate_report_dns`, este recibe como argumento la fecha para generar el reporte, y como argumento opcional, el host o hosts para los cuales se generara.

Ademas se modifico el target de `help` para tener una mejor visibilidad del los argumentos a utilizar

```bash
Variables configurables:
  HOST=<hostname>    Servidor destino (default: db-beta.imaxempresarial.com)
  PORT=<puerto>      Puerto destino (default: 80)
  DATE=<fecha>       Fecha en formato dd-mm-yy (default: hoy)
  HOSTS=[lista]      Lista de hosts para filtrar reportes

Targets disponibles:
  help                    Muestra los targets disponibles para el proyecto
  dns_check               Verifica resolución de DNS, Args: <HOST>, <PORT>
  result_dns              Muestra resultados de pruebas dns_check
  generate_report_dns     Genera reporte para pruebas de DNS realizadas, Args: <DATE> [HOSTS]
```

### Pruebas

Para ejecutar las pruebas del target `generate_report_dns`

```bash
make generate_report_dns DATE=01-10-25
```

Salida:

```bash
Reporte de pruebas DNS el 01-10-25
db-beta.imaxempresarial.com
db-betaimaxempresarial.com
imaxempresarial.com
===== REPORTE PARA LA FECHA 01-10-25 =====

===========================
HOST ANALIZADOS: 3
===========================
*********db-beta.imaxempresarial.com********
TOTAL: 1
SERVICE_OK: 100,0%
SERVICE_FAILD: 0,0%

*********db-betaimaxempresarial.com********
TOTAL: 1
SERVICE_OK: 0,0%
SERVICE_FAILD: 100,0%
CAUSE:
    * DNS_FAIL: 1

*********imaxempresarial.com********
TOTAL: 2
SERVICE_OK: 0,0%
SERVICE_FAILD: 100,0%
CAUSE:
    * TIMEOUT: 2


CONSOLIDADO:

TOTAL:      4
SUCCESS:    25,0%
FAILD:      75,0%
```

Generar solo para ciertos  hosts

```bash
make generate_report_dns DATE=01-10-25 HOSTS="imaxempresarial.com google.com"
```

Salida: 

```bash
Reporte de pruebas DNS el 01-10-25
imaxempresarial.com google.com
===== REPORTE PARA LA FECHA 01-10-25 =====

===========================
HOST ANALIZADOS: 1
===========================
*********imaxempresarial.com********
TOTAL: 2
SERVICE_OK: 0,0%
SERVICE_FAILD: 100,0%
CAUSE:
    * TIMEOUT: 2

*********google.com********
TOTAL: 0
SERVICE_OK: 0%
SERVICE_FAILD: 0%


CONSOLIDADO:

TOTAL:      2
SUCCESS:    0,0%
FAILD:      100,0%
```