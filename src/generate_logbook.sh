#!/usr/bin/env bash
# Genera reporte en terminal desde nc_result.csv generado por classify_failures.sh

set -euo pipefail

FILE=""
DATE=""
report_filter() {
  # Verificar que el archivo a analizar exista
  if [ ! -f "$FILE" ]; then
    echo "Archivo '$FILE' no encontrado"
    exit 1
  fi

  # Verificar que se ingreso la fecha con la cual filtrar
  if [ -z "$DATE" ]; then
    echo "Ingresar una fecha para generar el reporte"
    exit 1
  fi

  # Validar formato de fecha con regex
  if [[ ! "$DATE" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; then
      echo "Fecha inválida. Debe estar en formato dd-mm-yy (01-01-25)"
      exit 1
  fi

  # Quitamos el encabezado del archivo
  DATA=$(tail -n +2 "$FILE")

  # Filtrar las líneas que coincidan con la fecha
  DATA=$(grep "^$DATE" "$FILE")

  if [ -z "$DATA" ]; then
    echo "No hay registros para la fecha $DATE"
    exit 0
  fi

  # Lista opcional de hosts a filtrar
  HOST_FILTERS=("$@")  

  # Lista de hosts en DATA filtrada
  ALL_HOSTS=$(echo "$DATA" | awk -F"," '{gsub(/ /,"",$2); print $2}' | sort | uniq)

  # Determinar hosts a procesar
  if [ ${#HOST_FILTERS[@]} -gt 0 ]; then
      HOSTS="${HOST_FILTERS[@]}"
  else
      HOSTS="$ALL_HOSTS"
  fi
  
  echo "$HOSTS"

  echo "===== REPORTE PARA LA FECHA $DATE ====="
  echo

  TOTAL_GLOBAL=0
  OK_GLOBAL=0
  FAIL_GLOBAL=0

  echo "==========================="
  echo "HOST ANALIZADOS: $(echo "$HOSTS" | wc -l)"
  echo "==========================="

  for H in $HOSTS; do
    echo "*********$H********"
    
    TOTAL=$(echo "$DATA" | awk -F"," -v h="$H" '{gsub(/ /,"",$2); if($2==h) print}' | wc -l)
    OK=$(echo "$DATA" | awk -F"," -v h="$H" '{gsub(/ /,"",$2); if($2==h && $4 ~ /SERVICE_OK/) print}' | wc -l)
    FAIL=$((TOTAL - OK))
    
    # Porcentajes
    OK_PCT=$(awk "BEGIN {if ($TOTAL>0) printf \"%.1f\", ($OK/$TOTAL)*100; else print 0}")
    FAIL_PCT=$(awk "BEGIN {if ($TOTAL>0) printf \"%.1f\", ($FAIL/$TOTAL)*100; else print 0}")
    
    echo "TOTAL: $TOTAL"
    echo "SERVICE_OK: ${OK_PCT}%"
    echo "SERVICE_FAILD: ${FAIL_PCT}%"
    
    # Listado de causas por host
    echo "$DATA" | awk -F"," -v h="$H" '
      {
        gsub(/ /,"",$2);
        gsub(/ /,"",$4);
        if($2==h && $4 !~ /SERVICE_OK/) causas[$4]++
      }
      END {
        if (length(causas) > 0) {
          print "CAUSE:"
          for(c in causas) {
            printf "    * %s: %d\n", c, causas[c]
          }
        }
      }'
    echo
    
    # Acumulados globales
    TOTAL_GLOBAL=$((TOTAL_GLOBAL + TOTAL))
    OK_GLOBAL=$((OK_GLOBAL + OK))
    FAIL_GLOBAL=$((FAIL_GLOBAL + FAIL))
  done

  # Consolidado
  OK_GLOBAL_PCT=$(awk "BEGIN {if ($TOTAL_GLOBAL>0) printf \"%.1f\", ($OK_GLOBAL/$TOTAL_GLOBAL)*100; else print 0}")
  FAIL_GLOBAL_PCT=$(awk "BEGIN {if ($TOTAL_GLOBAL>0) printf \"%.1f\", ($FAIL_GLOBAL/$TOTAL_GLOBAL)*100; else print 0}")

  echo
  echo "CONSOLIDADO:"
  echo
  echo "TOTAL:      $TOTAL_GLOBAL"
  echo "SUCCESS:    ${OK_GLOBAL_PCT}%"
  echo "FAILD:      ${FAIL_GLOBAL_PCT}%"

}

show_help() {
  cat << EOF
Comando:
        $0 [OPCION] <archivo> <fecha> [host1 host2 ...]

OPCIONES:
  --report      Genera un reporte de conexión TCP filtrando por fecha y hosts opcionales.
  --help        Muestra este mensaje ayuda.

ARGUMENTOS OBLIGATORIOS:
  <archivo>     Ruta al archivo CSV que contiene los registros.
  <fecha>       Fecha para filtrar los registros en formato dd-mm-yy

ARGUMENTOS OPCIONALES:
  [host1 host2 ...]   Lista de hosts específicos a incluir en el reporte
EOF
}

case "${1:-}" in
  --reporte)
    FILE="$2"
    DATE="$3"
    shift 3
    report_filter "$@"
    ;;
  --help|*) 
    show_help
    exit 0
    ;;
esac