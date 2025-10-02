### Contrato de Salidas - TCP Smoke Tests

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

### 2. failure_classification.csv

**Formato**: CSV con 5 columnas

**Columnas**:
| Nombre | Descripción | Valores posibles |
|--------|-------------|------------------|
| host | Hostname probado | string |
| port | Puerto probado | integer |
| status | Estado del puerto | OPEN, CLOSED |
| failure_type | Categoría del fallo | DNS_FAILURE, FIREWALL, SERVICE_DOWN, SUCCESS, UNKNOWN |
| recommendation | Acción sugerida | string descriptivo |

**Validación**:
```bash
grep -E "DNS_FAILURE|FIREWALL|SERVICE_DOWN" out/failure_classification.csv

# Contar registros
wc -l out/tcp_probes.csv
**Ejemplo de contenido**:
```csv
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
2025-10-01 00:01:25,localhost,80,OPEN,6,LISTENING,no_pid,N/A
2025-10-01 00:01:31,10.255.255.1,80,CLOSED,N/A,N/A,TIMEOUT
