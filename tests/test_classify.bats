#!/usr/bin/env bats

setup() {
    export OUTPUT_DIR="out/test_classify"
    mkdir -p "$OUTPUT_DIR"
}

teardown() {
    rm -rf "$OUTPUT_DIR"
}

@test "classify_failures.sh auto debe generar failure_classification.csv" {
    # Crear CSV de entrada simulado
    cat > "$OUTPUT_DIR/tcp_probes.csv" << EOF
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-01 00:01:19,google.com,80,OPEN,46,N/A,N/A
2025-10-01 00:01:25,badhost.invalid,80,CLOSED,N/A,N/A,DNS_FAILURE
2025-10-01 00:01:31,10.255.255.1,80,CLOSED,N/A,N/A,TIMEOUT
EOF
    
    export INPUT_FILE="$OUTPUT_DIR/tcp_probes.csv"
    
    run ./src/classify_failures.sh auto
    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_DIR/failure_classification.csv" ]
    
    # Verificar contenido
    grep -q "DNS_FAILURE" "$OUTPUT_DIR/failure_classification.csv"
    grep -q "FIREWALL" "$OUTPUT_DIR/failure_classification.csv"
    grep -q "SUCCESS" "$OUTPUT_DIR/failure_classification.csv"
}

@test "dns_check debe detectar fallo de DNS" {
    run ./src/classify_failures.sh dns_check invalid.domain.test 80 "$OUTPUT_DIR"
    [ "$status" -eq 0 ]
    
    [ -f "$OUTPUT_DIR/nc_result.csv" ]
    grep -q "DNS_FAIL" "$OUTPUT_DIR/nc_result.csv"
}

@test "dns_check debe detectar timeout" {
    run timeout 10 ./src/classify_failures.sh dns_check 10.255.255.1 80 "$OUTPUT_DIR"
    [ "$status" -eq 0 ]
    
    grep -q "TIMEOUT" "$OUTPUT_DIR/nc_result.csv"
}