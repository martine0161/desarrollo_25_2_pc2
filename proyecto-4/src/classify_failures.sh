#!/usr/bin/env bash
# Clasifica segun tipos de errores para resolución de DNS
set -euo pipefail

# Función para mapear errores de resolucion de NDS
dns_check() {
  local HOST="${1:-}"
  local PORT="${2:-}"
  local OUTPUT_DIR="${3:-./out}"
  local BITACORA="${OUTPUT_DIR}/bitacora.csv"

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

  # Crear bitacora.csv si no existe con encabezado
  if [ ! -f "$BITACORA" ]; then
    echo "timestamp, host, port, cause" > "$BITACORA"
  fi

  # Crear archivo temporal
  TMP=$(mktemp)
  trap 'rm -f "$TMP"' EXIT

  set +e
  # Ejecuta nc con timeout ignorando errores que puedan ocurrir
  nc -4 -vzw3 "$HOST" "$PORT" >"$TMP" 2>&1
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

  # Registrar en bitacora
  ts="$(date -u +"%d-%m-%y %H:%M:%S")"
  echo "$ts, $HOST, $PORT, $cause" >> "$BITACORA"

  # Mostrar resultado en consola
  echo "$HOST $PORT"
  echo "====================================="
  echo "Result: $cause"
}

# Función para mostrar el reporte en bitacora
show_report() {
    local OUTPUT_DIR="${1:-./out}"
    local BITACORA="${OUTPUT_DIR}/bitacora.csv"

    if [ ! -f "$BITACORA" ]; then
        echo "No hay datos de bitácora en $BITACORA" >&2
        return 1
    fi

    echo "Reporte de monitoreo:"
    echo "===================="
    cat "$BITACORA" | column -t -s ","
}

# Función de ayuda
show_help() {
    cat << EOF
Uso: $0 <comando> [parámetros]

Comandos disponibles:
  dns_check <host> <puerto> [out_dir]  - Resuelve DNS de host ingresado
  show_report [out_dir]                - Muestra el reporte de bitácora
  help                                 - Muestra esta ayuda
EOF
}

case "${1:-help}" in
    dns_check) shift; dns_check "$@" ;;
    show_report)  shift; show_report "${@:-./out}" ;;
    help|*)  show_help ;;
esac
