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

# Función para clasificar tipo de fallo
classify_failure() {
    local host=$1
    local port=$2
    local error_output=$3
    
    # Si no hay mensaje de error, asumimos timeout
    if [[ -z "$error_output" ]]; then
        echo "TIMEOUT"
        return
    fi
    
    case "$error_output" in
        *"Connection refused"*)
            echo "PORT_CLOSED"
            ;;
        *"No route to host"*)
            echo "NETWORK_UNREACHABLE"
            ;;
        *"Name or service not known"*)
            echo "DNS_FAILURE"
            ;;
        *"Connection timed out"*)
            echo "TIMEOUT"
            ;;
        *)
            echo "UNKNOWN_ERROR"
            ;;
    esac
}

# Función para analizar estado detallado
analyze_local_socket() {
    local port=$1
    
    # Verificar si hay proceso escuchando
    local listening=$(ss -ltnp 2>/dev/null | grep ":$port " || echo "")
    
    if [[ -n "$listening" ]]; then
        # Extraer PID y proceso
        local process_info=$(echo "$listening" | grep -o 'pid=[0-9]*' | head -1 || echo "no_pid")
        echo "LISTENING,$process_info"
    else
        echo "NOT_LISTENING,no_process"
    fi
}

# Función para medir latencia básica
time_connection() {
    local host=$1
    local port=$2
    local start_time=$(date +%s%3N)
    
    if timeout 1 nc -z "$host" "$port" 2>/dev/null; then
        local end_time=$(date +%s%3N)
        echo $((end_time - start_time))
    else
        echo "N/A"
    fi
}

# Función principal de sondeo
probe_tcp_port() {
    local host=$1
    local port=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local start_time=$(date +%s)
    
    # Usar comando timeout para forzar el límite
    local error_output
    error_output=$(timeout "$TIMEOUT_SEC" nc -z "$host" "$port" 2>&1) || true
    local nc_exit=$?
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    local status
    local latency_ms
    local failure_reason
    
    # Verificar conexión exitosa
    if timeout "$TIMEOUT_SEC" nc -z "$host" "$port" 2>/dev/null; then
        status="OPEN"
        latency_ms=$(time_connection "$host" "$port")
        failure_reason="N/A"
    else
        status="CLOSED"
        latency_ms="N/A"
        
        # Exit code 124 significa timeout del comando timeout
        if [[ $nc_exit -eq 124 ]]; then
            failure_reason="TIMEOUT"
        # Si fue rápido, clasificar por mensaje
        elif [[ $elapsed -lt $((TIMEOUT_SEC - 1)) ]]; then
            failure_reason=$(classify_failure "$host" "$port" "$error_output")
        else
            failure_reason="TIMEOUT"
        fi
    fi
    
    # Verificar estado con ss (para localhost)
    local socket_state="N/A"
    if [[ "$host" == "localhost" || "$host" == "127.0.0.1" ]]; then
        socket_state=$(analyze_local_socket "$port")
    fi
    
    echo "$timestamp,$host,$port,$status,$latency_ms,$socket_state,$failure_reason"
}

# Crear directorio de salida
mkdir -p "$OUTPUT_DIR"

# Generar header CSV
echo "timestamp,host,port,status,latency_ms,socket_state,failure_reason" > "$OUTPUT_DIR/tcp_probes.csv"

# Procesar todos los hosts y puertos
IFS=',' read -ra HOST_ARRAY <<< "$HOSTS"
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

for host in "${HOST_ARRAY[@]}"; do
    for port in "${PORT_ARRAY[@]}"; do
        probe_tcp_port "$host" "$port" >> "$OUTPUT_DIR/tcp_probes.csv"
    done
done

echo "Sondeo completado. Resultados en: $OUTPUT_DIR/tcp_probes.csv"
