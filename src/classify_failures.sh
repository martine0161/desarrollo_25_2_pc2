#!/usr/bin/env bash
# Clasifica segun tipos de errores para resolución de DNS
set -euo pipefail

FILE_OUTPUT="nc_result.csv"
RAW_FILE_OUTPUT="raw_result.csv"

# Función para mapear errores de resolucion de DNS
dns_check() {
  local HOST="${1:-}"
  local PORT="${2:-}"
  local OUTPUT_DIR="${3:-./out}"
  local PATH_FILE_OUTPUT="${OUTPUT_DIR}/${FILE_OUTPUT}"
  local PATH_RAW_OUTPUT="${OUTPUT_DIR}/${RAW_FILE_OUTPUT}"

  # Verifica que los parametros HOST y PORT se ingresen
  if [ -z "$HOST" ] || [ -z "$PORT" ]; then
    echo "ERROR: No se proporcionaron los parámetros requeridos" >&2
    echo "Sintaxis: $0 <HOST> <PORT>" >&2
    echo "Ejemplo: $0 localhost 8080" >&2
    exit 1
  fi

  # Crear directorio si no existe
  if ! mkdir -p "$OUTPUT_DIR" 2>/dev/null; then
      echo "Error: No se pudo crear el directorio $OUTPUT_DIR" >&2
      exit 1
  fi

  # Crear raw_result.csv si no existe con encabezado
  if [ ! -f "$PATH_RAW_OUTPUT" ]; then
    echo "timestamp, host, port, output" > "$PATH_RAW_OUTPUT"
  fi

  # Crear nc_result.csv si no existe con encabezado
  if [ ! -f "$PATH_FILE_OUTPUT" ]; then
    echo "timestamp, host, port, cause" > "$PATH_FILE_OUTPUT"
  fi

  # Crear archivo temporal
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  set +e
  # Ejecuta nc con timeout ignorando errores que puedan ocurrir
  nc -4 -vzw3 "$HOST" "$PORT" 2>&1 | tail -n 1 >"$TMP"
  exitcode=$?
  set -e
  
  # Revisa que tipo de fallo se registro en la prueba
  classify() {
    local f="$1"
    local code="$2"

    if [ "$code" -eq 0 ]; then
      echo "SERVICE_OK"
    elif grep -qiE "Name or service not known|Temporary failure in name resolution" "$f"; then
      echo "DNS_FAIL"
    elif grep -qi "timed out" "$f"; then
      echo "TIMEOUT"
    elif grep -qi "Connection refused" "$f"; then
      echo "CONN_REFUSED"
    elif grep -qiE "No route to host|Administratively prohibited" "$f"; then
      echo "FIREWALL_REJECT"
    else
      echo "UNKNOWN"
    fi
  }

  cause="$(classify "$TMP" "$exitcode")"

  # Verificar estado de ss como complemento
  if [ "$cause" = "CONN_REFUSED" ]; then
    if ss -tlnp 2>/dev/null | grep -qE ":$PORT\\b"; then
      # Inconsistencia: puerto escuchando pero nc falló
      echo "Puerto $PORT abierto, pero nc fallo al tratar de conectarse" 
      cause="UNKNOWN"
    else
      echo "Puerto $PORT cerrado"
    fi
  fi

  raw_output="$(tr -d '\n' < "$TMP" | sed 's/  */ /g')"

  ts="$(date -u +"%d-%m-%y %H:%M:%S")"
  echo "$ts, $HOST, $PORT, $cause" >> "$PATH_FILE_OUTPUT"
  echo "$ts, $HOST, $PORT, $raw_output" >> "$PATH_RAW_OUTPUT"

  # Mostrar resultado en consola
  echo "$HOST $PORT"
  echo "====================================="
  echo "Result: $cause"
}

# Función para mostrar el reporte en bitacora
show_report() {
    local OUTPUT_DIR="${1:-./out}"
    local PATH_FILE_OUTPUT="${OUTPUT_DIR}/${FILE_OUTPUT}"

    if [ ! -f "$PATH_FILE_OUTPUT" ]; then
        echo "No hay datos de bitácora en $PATH_FILE_OUTPUT" >&2
        return 1
    fi

    echo "Reporte de monitoreo:"
    echo "===================="
    cat "$PATH_FILE_OUTPUT" | column -t -s ","
}

# Nueva función para flujo automático desde probe_tcp.sh
auto_classify() {
    local INPUT_FILE="${INPUT_FILE:-${OUTPUT_DIR:-out}/tcp_probes.csv}"
    local OUTPUT_FILE="${OUTPUT_DIR:-out}/failure_classification.csv"
    
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: No se encontró $INPUT_FILE" >&2
        return 1
    fi
    
    echo "host,port,status,failure_type,recommendation" > "$OUTPUT_FILE"
    
    # Leer CSV y clasificar cada línea
    tail -n +2 "$INPUT_FILE" | while IFS=',' read -r timestamp host port status latency socket failure_reason; do
        # Limpiar espacios
        host=$(echo "$host" | tr -d ' ')
        port=$(echo "$port" | tr -d ' ')
        status=$(echo "$status" | tr -d ' ')
        failure_reason=$(echo "$failure_reason" | tr -d ' ')
        
        local failure_type=""
        local recommendation=""
        
        case "$failure_reason" in
            "DNS_FAILURE")
                failure_type="DNS_FAILURE"
                recommendation="Verificar resolución DNS"
                ;;
            "TIMEOUT")
                failure_type="FIREWALL"
                recommendation="Revisar reglas de firewall"
                ;;
            "PORT_CLOSED")
                failure_type="SERVICE_DOWN"
                recommendation="Verificar si servicio está corriendo"
                ;;
            "N/A")
                failure_type="SUCCESS"
                recommendation="Puerto accesible - OK"
                ;;
            *)
                failure_type="UNKNOWN"
                recommendation="Investigar causa específica"
                ;;
        esac
        
        echo "$host,$port,$status,$failure_type,$recommendation" >> "$OUTPUT_FILE"
    done
    
    echo "Clasificación completada: $OUTPUT_FILE"
}

# Función de ayuda
show_help() {
    cat << EOF
Uso: $0 <comando> [parámetros]

Comandos disponibles:
  auto                                 - Clasificación automática desde tcp_probes.csv (DEFAULT)
  dns_check <host> <puerto> [out_dir]  - Resuelve DNS de host ingresado
  show_report [out_dir]                - Muestra el reporte generado por dns_check
  help                                 - Muestra esta ayuda
EOF
}

# UN SOLO CASE - Modificado para incluir auto_classify como default
case "${1:-auto}" in
    dns_check) 
        shift
        dns_check "$@"
        ;;
    show_report)
        shift
        show_report "${@:-./out}"
        ;;
    auto)
        auto_classify
        ;;
    help)
        show_help
        ;;
    *)
        auto_classify
        ;;
esac