# Bitácora Sprint 3 - Validación e Integración Final

**Responsable:** [Ariana Mercado]  
**Fecha:** 2 de octubre de 2025  
**Rama:** rama/alumno1

## Comandos Ejecutados

### Validación de idempotencia
```bash
$ make clean
$ time make run
real    0m6.234s

$ cp out/tcp_probes.csv out/primera_ejecucion.csv
$ wc -l out/primera_ejecucion.csv
10 out/primera_ejecucion.csv

$ time make run
real    0m6.189s

$ cp out/tcp_probes.csv out/segunda_ejecucion.csv
$ wc -l out/segunda_ejecucion.csv
10 out/segunda_ejecucion.csv
```
### Verificacion idempotencia
![Resultados exitosos](imagenes/Idempotencia)
