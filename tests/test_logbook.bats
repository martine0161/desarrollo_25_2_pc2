#!/usr/bin/env bats

setup() {
    export OUTPUT_DIR="out/test_logbook"
    export HOSTS="google.com,localhost"
    export PORTS="80,22"
    export TIMEOUT_SEC="3"
    mkdir -p "$OUTPUT_DIR"
}

teardown() {
    rm -rf "$OUTPUT_DIR"
}

@test "generate_logbook.sh auto debe crear bitácora" {
    # Crear datos simulados
    cat > "$OUTPUT_DIR/tcp_probes.csv" << EOF
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
2025-10-01 00:01:25,google.com,9999,CLOSED,N/A,N/A,TIMEOUT
2025-10-01 00:01:31,localhost,22,OPEN,2,LISTENING,N/A
EOF
    
    run ./src/generate_logbook.sh auto
    [ "$status" -eq 0 ]
    
    # Verificar que existe bitácora
    ls "$OUTPUT_DIR"/operational_logbook_*.txt
}

@test "bitácora debe contener secciones obligatorias" {
    cat > "$OUTPUT_DIR/tcp_probes.csv" << EOF
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
EOF
    
    ./src/generate_logbook.sh auto
    
    logbook=$(ls "$OUTPUT_DIR"/operational_logbook_*.txt | head -1)
    
    grep -q "RESUMEN EJECUTIVO" "$logbook"
    grep -q "PUERTOS ABIERTOS" "$logbook"
    grep -q "EVIDENCIAS" "$logbook"
}