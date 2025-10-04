# Bitácora Sprint 3 - Test con Bats

Implementa test para `classify_failures.sh`

### Objetivos:

Generar el test `test_classify.bats` para validar que las ejecución de las funciones de `classify_failures.sh` se ejecuten según lo esperado y validar que se creen los archivos necesarios en la ejecución.

### Puntos a desarrollar

* Test para verificar ejecución de help sin errores
* Test para verificar creación de archivos de salida esperados y encabezado.
* Test para verificar creación de directorios esperados
* Test para validar contenido de mensaje de show_help
* Test para validar que una ejecución sin parámetros termine con error

### Target agregado a Makefile para test

Se agrego target `test_classify_failures` en Makefile para ejecución del test

```bash
 HOST=<hostname>    Servidor destino (default: db-beta.imaxempresarial.com)
  PORT=<puerto>      Puerto destino (default: 80)
  DATE=[fecha]       Fecha en formato dd-mm-yy (default: hoy)
  HOSTS=[lista]      Lista de hosts para filtrar reportes

Targets disponibles:
  help                    Muestra los targets disponibles para el proyecto
  dns_check               Verifica resolución de DNS, Args: <HOST>, <PORT>
  result_dns              Muestra resultados de pruebas dns_check
  generate_report_dns     Genera reporte para pruebas de DNS realizadas, Args: [DATE] [HOSTS]
  test_classify_failures  Ejecuta test con bats
  ```

### Pruebas

Ejecutar pruebas desde Makefile

```bash
make test_classify_failures
```

Salida:

```bash
Iniciando test para classify_failures.sh
 ✓ script existe 
 ✓ show_help muestra información de uso 
 ✓ dns_check sin parámetros muestra error 
 ✓ dns_check crea un directorio de salida 
 ✓ dns_check crea archivos CSV con encabezados 
 ✓ El comando de help funciona 

6 tests, 0 failures
```
