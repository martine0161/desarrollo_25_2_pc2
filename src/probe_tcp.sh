#!/bin/bash
set -euo pipefail

# Variables de configuración
HOSTS=${HOSTS:-"google.com,github.com,localhost"}
PORTS=${PORTS:-"80,443,22"}
TIMEOUT_SEC=${TIMEOUT_SEC:-5}
OUTPUT_DIR=${OUTPUT_DIR:-"out"}

# Función de limpieza
cleanup() {
    echo "Limpiando recursos temporales..."
}
trap cleanup EXIT

# Función principal de sondeo
probe_tcp_port() {
    local host=$1
    local port=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Verificar con nc
    if nc -z -w "$TIMEOUT_SEC" "$host" "$port" 2>/dev/null; then
        status="OPEN"
        latency_ms=$(time_connection "$host" "$port")
    else
        status="CLOSED"
        latency_ms="N/A"
    fi
    
    # Verificar estado con ss (para localhost)
    socket_state="N/A"
    if [[ "$host" == "localhost" || "$host" == "127.0.0.1" ]]; then
        socket_state=$(ss -ltn | grep ":$port " | awk '{print $1}' || echo "NOT_LISTENING")
    fi
    
    # Generar línea CSV
    echo "$timestamp,$host,$port,$status,$latency_ms,$socket_state"
}

# Función para medir latencia básica
time_connection() {
    local host=$1
    local port=$2
    local start_time=$(date +%s%3N)
    
    if nc -z -w 1 "$host" "$port" 2>/dev/null; then
        local end_time=$(date +%s%3N)
        echo $((end_time - start_time))
    else
        echo "N/A"
    fi
}

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Generar header CSV
echo "timestamp,host,port,status,latency_ms,socket_state" > "$OUTPUT_DIR/tcp_probes.csv"

# Procesar todos los hosts y puertos
IFS=',' read -ra HOST_ARRAY <<< "$HOSTS"
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

for host in "${HOST_ARRAY[@]}"; do
    for port in "${PORT_ARRAY[@]}"; do
        probe_tcp_port "$host" "$port" >> "$OUTPUT_DIR/tcp_probes.csv"
    done
done

echo "Sondeo completado. Resultados en: $OUTPUT_DIR/tcp_probes.csv"
