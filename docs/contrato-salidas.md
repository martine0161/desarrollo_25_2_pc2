# Contrato de Salidas - TCP Probes

## Archivos Generados

### out/tcp_probes.csv

**Ubicación**: `out/tcp_probes.csv`

**Formato**: CSV con 7 columnas separadas por coma

**Columnas**:
1. timestamp - Fecha y hora en formato YYYY-MM-DD HH:MM:SS
2. host - Hostname o IP probada
3. port - Puerto TCP probado
4. status - OPEN o CLOSED
5. latency_ms - Latencia en milisegundos o N/A
6. socket_state - Estado del socket (LISTEN, NOT_LISTENING, N/A)
7. failure_reason - Clasificación de fallo (TIMEOUT, PORT_CLOSED, DNS_FAILURE, N/A)

**Ejemplo de contenido**:
```csv
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
2025-10-01 00:01:25,localhost,80,OPEN,6,LISTENING,no_pid,N/A
2025-10-01 00:01:31,10.255.255.1,80,CLOSED,N/A,N/A,TIMEOUT
