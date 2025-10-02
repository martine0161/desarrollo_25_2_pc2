#!/usr/bin/env bash
set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-out}"
TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

cleanup() {
    echo "Finalizando generación de bitácora..."
}
trap cleanup EXIT

# Generar bitácora automática desde los CSVs del flujo
auto_logbook() {
    local PROBE_FILE="${OUTPUT_DIR}/tcp_probes.csv"
    local CLASS_FILE="${OUTPUT_DIR}/failure_classification.csv"
    local LOGBOOK="${OUTPUT_DIR}/operational_logbook_${TIMESTAMP}.txt"
    
    if [ ! -f "$PROBE_FILE" ]; then
        echo "Error: No se encontró $PROBE_FILE" >&2
        return 1
    fi
    
    cat > "$LOGBOOK" << EOF
========================================
BITÁCORA OPERATIVA TCP SMOKE TESTS
========================================
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Variables: HOSTS=${HOSTS:-N/A}, PORTS=${PORTS:-N/A}, TIMEOUT=${TIMEOUT_SEC:-N/A}s

RESUMEN EJECUTIVO
-----------------
EOF
    
    # Estadísticas generales
    local total=$(tail -n +2 "$PROBE_FILE" | wc -l)
    local open=$(tail -n +2 "$PROBE_FILE" | awk -F',' '$4 ~ /OPEN/' | wc -l)
    local closed=$(tail -n +2 "$PROBE_FILE" | awk -F',' '$4 ~ /CLOSED/' | wc -l)
    
    cat >> "$LOGBOOK" << EOF
Total de pruebas: $total
Puertos abiertos: $open ($(awk "BEGIN {printf \"%.1f\", ($open/$total)*100}")%)
Puertos cerrados: $closed ($(awk "BEGIN {printf \"%.1f\", ($closed/$total)*100}")%)

PUERTOS ABIERTOS
----------------
EOF
    
    tail -n +2 "$PROBE_FILE" | awk -F',' '$4 ~ /OPEN/ {print "- " $2 ":" $3 " (latencia: " $5 "ms)"}' >> "$LOGBOOK"
    
    echo "" >> "$LOGBOOK"
    echo "FALLOS DETECTADOS" >> "$LOGBOOK"
    echo "-----------------" >> "$LOGBOOK"
    
    tail -n +2 "$PROBE_FILE" | awk -F',' '$4 ~ /CLOSED/ {print $7}' | \
        sort | uniq -c | \
        awk '{print "- " $2 ": " $1 " ocurrencias"}' >> "$LOGBOOK"
    
    if [ -f "$CLASS_FILE" ]; then
        echo "" >> "$LOGBOOK"
        echo "RECOMENDACIONES" >> "$LOGBOOK"
        echo "---------------" >> "$LOGBOOK"
        tail -n +2 "$CLASS_FILE" | awk -F',' '$4 != "SUCCESS" {print "- " $1 ":" $2 " → " $5}' >> "$LOGBOOK"
    fi
    
    cat >> "$LOGBOOK" << EOF

EVIDENCIAS
----------
- Sondeo: tcp_probes.csv
- Clasificación: failure_classification.csv
- Bitácora: $(basename $LOGBOOK)

========================================
EOF
    
    echo "Bitácora generada: $LOGBOOK"
    cat "$LOGBOOK"
}

# Función original report_filter (mantener para compatibilidad)
report_filter() {
    local FILE="${1:-}"
    local DATE="${2:-}"
    
    if [ -z "$FILE" ] || [ -z "$DATE" ]; then
        echo "Error: Función legacy requiere FILE y DATE"
        return 1
    fi
    
    # ... tu código original ...
    echo "Nota: Esta es la función legacy. Usa 'auto' para flujo automático."
}

show_help() {
    cat << EOF
Uso: $0 [comando] [parámetros]

Comandos:
  auto                              - Genera bitácora automática (DEFAULT)
  --reporte <archivo> <fecha>       - Función legacy para reportes filtrados
  --help                            - Muestra esta ayuda

Ejemplos:
  $0                                # Modo auto
  $0 auto                           # Modo auto explícito
  $0 --reporte out/nc_result.csv 02-10-25
EOF
}

case "${1:-auto}" in
    auto) 
        auto_logbook 
        ;;
    --reporte) 
        shift
        FILE="$1"
        DATE="$2"
        shift 2
        report_filter "$FILE" "$DATE" "$@"
        ;;
    --help|*) 
        show_help
        ;;
esac