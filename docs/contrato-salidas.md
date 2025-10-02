```markdown
# Contrato de Salidas - TCP Smoke Tests

## Archivos Generados en `out/`

### 1. tcp_probes.csv

**Formato**: CSV con 7 columnas separadas por coma

**Columnas**:
| # | Nombre | Tipo | Descripción | Ejemplo |
|---|--------|------|-------------|---------|
| 1 | timestamp | datetime | Fecha y hora formato YYYY-MM-DD HH:MM:SS | 2025-10-01 00:01:19 |
| 2 | host | string | Hostname o IP probada | google.com |
| 3 | port | integer | Puerto TCP probado | 80 |
| 4 | status | enum | OPEN o CLOSED | OPEN |
| 5 | latency_ms | integer/NA | Latencia en milisegundos | 46 |
| 6 | socket_state | string | LISTENING,pid=X o NOT_LISTENING o N/A | LISTENING,pid=1234 |
| 7 | failure_reason | string | TIMEOUT, PORT_CLOSED, DNS_FAILURE, N/A | N/A |

**Ejemplo de contenido**:
```csv
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
2025-10-01 00:01:25,localhost,80,OPEN,6,LISTENING,no_pid,N/A
2025-10-01 00:01:31,10.255.255.1,80,CLOSED,N/A,N/A,TIMEOUT
```

**Validación**:
```bash
# Verificar formato
head -1 out/tcp_probes.csv | grep -q "timestamp,host,port,status"

# Contar registros
wc -l out/tcp_probes.csv
```

---

### 2. failure_classification.csv

**Formato**: CSV con 5 columnas separadas por coma

**Columnas**:
| # | Nombre | Tipo | Descripción | Ejemplo |
|---|--------|------|-------------|---------|
| 1 | host | string | Hostname probado | google.com |
| 2 | port | integer | Puerto TCP probado | 80 |
| 3 | status | enum | OPEN o CLOSED | CLOSED |
| 4 | failure_type | string | Categoría del fallo | FIREWALL |
| 5 | recommendation | string | Acción sugerida | Revisar reglas de firewall |

**Valores posibles para failure_type**:
- `DNS_FAILURE`: Error de resolución DNS
- `FIREWALL`: Timeout o bloqueo de firewall
- `SERVICE_DOWN`: Puerto cerrado o servicio detenido
- `SUCCESS`: Puerto accesible correctamente
- `UNKNOWN`: Causa no identificada

**Ejemplo de contenido**:
```csv
host,port,status,failure_type,recommendation
google.com,80,OPEN,SUCCESS,Puerto accesible - OK
google.com,9999,CLOSED,FIREWALL,Revisar reglas de firewall
invalid.host,80,CLOSED,DNS_FAILURE,Verificar resolución DNS
localhost,22,OPEN,SUCCESS,Puerto accesible - OK
```

**Validación**:
```bash
# Verificar que contiene clasificaciones
grep -E "DNS_FAILURE|FIREWALL|SERVICE_DOWN" out/failure_classification.csv

# Contar registros
wc -l out/failure_classification.csv
```

---

### 3. operational_logbook_*.txt

**Formato**: Texto plano estructurado

**Nomenclatura**: `operational_logbook_YYYY-MM-DD_HH-MM-SS.txt`
- El `*` representa el timestamp de generación
- Cada ejecución de `make run` crea un archivo único

**Secciones obligatorias**:
1. **Encabezado**: Título y fecha de ejecución
2. **Resumen Ejecutivo**: Estadísticas generales
3. **Puertos Abiertos**: Lista con latencias
4. **Fallos Detectados**: Conteo por tipo
5. **Recomendaciones**: Acciones sugeridas
6. **Evidencias**: Referencias a archivos

**Ejemplo de contenido**:
```txt
========================================
BITÁCORA OPERATIVA TCP SMOKE TESTS
========================================
Fecha: 2025-10-02 14:30:45
Variables: HOSTS=google.com,localhost, PORTS=80,443,9999, TIMEOUT=5s

RESUMEN EJECUTIVO
-----------------
Total de pruebas: 6
Puertos abiertos: 4 (66.7%)
Puertos cerrados: 2 (33.3%)

PUERTOS ABIERTOS
----------------
- google.com:80 (latencia: 45ms)
- google.com:443 (latencia: 52ms)
- localhost:80 (latencia: 2ms)
- localhost:443 (latencia: 3ms)

FALLOS DETECTADOS
-----------------
- TIMEOUT: 1 ocurrencias
- PORT_CLOSED: 1 ocurrencias

RECOMENDACIONES
---------------
- google.com:9999 → Revisar reglas de firewall
- localhost:8080 → Verificar si servicio está corriendo

EVIDENCIAS
----------
- Sondeo: tcp_probes.csv
- Clasificación: failure_classification.csv
- Bitácora: operational_logbook_2025-10-02_14-30-45.txt

========================================
```

**Validación**:
```bash
# Listar todos los logbooks generados
ls out/operational_logbook_*.txt

# Verificar secciones obligatorias
grep "RESUMEN EJECUTIVO" out/operational_logbook_*.txt
grep "PUERTOS ABIERTOS" out/operational_logbook_*.txt
grep "EVIDENCIAS" out/operational_logbook_*.txt

# Ver el más reciente
cat $(ls -t out/operational_logbook_*.txt | head -1)
```

---

## Códigos de Salida

| Código | Script | Significado |
|--------|--------|-------------|
| 0 | Todos | Ejecución exitosa |
| 1 | classify_failures.sh | Error: archivo no encontrado o parámetros faltantes |
| 1 | generate_logbook.sh | Error: tcp_probes.csv no encontrado |
| 124 | probe_tcp.sh (interno) | Timeout forzado por comando `timeout` |

**Uso de códigos de salida**:
```bash
# Verificar éxito del flujo completo
make run
if [ $? -eq 0 ]; then
    echo "Flujo completado exitosamente"
fi

# Detectar errores específicos
./src/classify_failures.sh auto
case $? in
    0) echo "Clasificación exitosa" ;;
    1) echo "Error: archivo no encontrado" ;;
    *) echo "Error desconocido" ;;
esac
```