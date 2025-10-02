#!/usr/bin/env bats
# test_integration.bats - Suite de pruebas de integración

TEST_OUTPUT_DIR="out/bats_test"
TEST_DIST_DIR="dist/bats_test"

setup() {
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR" 2>/dev/null || true
    mkdir -p "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR"
    export OUTPUT_DIR="$TEST_OUTPUT_DIR"
    export DIST_DIR="$TEST_DIST_DIR"
}

teardown() {
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR" 2>/dev/null || true
}

#############################
# ESTRUCTURA Y ARCHIVOS     #
#############################

@test "Proyecto tiene estructura mínima requerida" {
    [ -f "Makefile" ]
    [ -d "src" ]
    [ -d "tests" ]
    [ -d "docs" ]
    [ -f "src/probe_tcp.sh" ]
    [ -f "src/classify_failures.sh" ]
    [ -f "src/generate_logbook.sh" ]
}

@test "Documentación completa" {
    [ -f "docs/README.md" ]
    [ -f "docs/contrato-salidas.md" ]
    [ -f "docs/bitacora-sprint-1.md" ]
    [ -f "docs/bitacora-sprint-2.md" ]
    [ -f "docs/bitacora-sprint-3.md" ]
}

@test "Scripts tienen permisos de ejecución" {
    [ -x "src/probe_tcp.sh" ]
    [ -x "src/classify_failures.sh" ]
    [ -x "src/generate_logbook.sh" ]
}

#############################
# TARGETS MAKEFILE          #
#############################

@test "Makefile tiene todos los targets obligatorios" {
    grep -q "^tools:" Makefile
    grep -q "^build:" Makefile
    grep -q "^test:" Makefile
    grep -q "^run:" Makefile
    grep -q "^pack:" Makefile
    grep -q "^clean:" Makefile
    grep -q "^help:" Makefile
}

@test "make tools verifica herramientas" {
    run timeout 10 make tools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "nc" ]]
    [[ "$output" =~ "ss" ]]
}

@test "make help muestra información" {
    run timeout 10 make help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tools" ]]
    [[ "$output" =~ "build" ]]
    [[ "$output" =~ "HOSTS" ]]
}

@test "make info muestra configuración" {
    run timeout 10 make info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tcp-smoke" ]]
}

@test "make build crea directorios" {
    run timeout 10 make build OUTPUT_DIR="$TEST_OUTPUT_DIR" DIST_DIR="$TEST_DIST_DIR"
    [ "$status" -eq 0 ]
    [ -d "$TEST_OUTPUT_DIR" ]
    [ -f "$TEST_OUTPUT_DIR/build.info" ]
}

#############################
# EJECUCIÓN DE SCRIPTS      #
#############################

@test "probe_tcp.sh genera CSV válido" {
    export HOSTS="localhost"
    export PORTS="22"
    export TIMEOUT_SEC="2"
    
    run timeout 15 ./src/probe_tcp.sh
    [ "$status" -eq 0 ]
    [ -f "out/tcp_probes.csv" ]
    
    # Verificar header
    head -1 out/tcp_probes.csv | grep -q "timestamp,host,port"
}

@test "classify_failures.sh funciona en modo auto" {
    # Crear CSV de entrada
    cat > "$TEST_OUTPUT_DIR/tcp_probes.csv" << EOF
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-02 14:30:15,google.com,80,OPEN,46,N/A,N/A
2025-10-02 14:30:16,invalid.host,80,CLOSED,N/A,N/A,DNS_FAILURE
EOF
    
    export INPUT_FILE="$TEST_OUTPUT_DIR/tcp_probes.csv"
    
    run timeout 10 ./src/classify_failures.sh auto
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT_DIR/failure_classification.csv" ]
}

@test "generate_logbook.sh crea bitácora" {
    # Crear CSV de entrada
    cat > "$TEST_OUTPUT_DIR/tcp_probes.csv" << EOF
timestamp,host,port,status,latency_ms,socket_state,failure_reason
2025-10-02 14:30:15,google.com,80,OPEN,46,N/A,N/A
EOF
    
    run timeout 10 ./src/generate_logbook.sh auto
    [ "$status" -eq 0 ]
    
    # Verificar que se creó bitácora
    ls "$TEST_OUTPUT_DIR"/operational_logbook_*.txt
}

#############################
# VALIDACIÓN DE FORMATO     #
#############################

@test "Contrato de salidas está documentado" {
    grep -q "tcp_probes.csv" docs/contrato-salidas.md
    grep -q "failure_classification.csv" docs/contrato-salidas.md
    grep -q "operational_logbook" docs/contrato-salidas.md
}

@test "README documenta variables de entorno" {
    grep -q "HOSTS" docs/README.md
    grep -q "PORTS" docs/README.md
    grep -q "TIMEOUT_SEC" docs/README.md
    grep -q "OUTPUT_DIR" docs/README.md
}

@test "Variables tienen valores por defecto en Makefile" {
    grep -q "HOSTS ?=" Makefile
    grep -q "PORTS ?=" Makefile
    grep -q "TIMEOUT_SEC ?=" Makefile
}

#############################
# REGLAS PATRÓN             #
#############################

@test "Regla patrón CSV a TXT funciona" {
    echo "host,port,status" > "$TEST_OUTPUT_DIR/test.csv"
    echo "google.com,80,OPEN" >> "$TEST_OUTPUT_DIR/test.csv"
    
    run timeout 10 make "$TEST_OUTPUT_DIR/test.txt"
    [ "$status" -eq 0 ]
    [ -f "$TEST_OUTPUT_DIR/test.txt" ]
    
    # Verificar formato tabulado
    grep -q $'\t' "$TEST_OUTPUT_DIR/test.txt"
}

#############################
# ROBUSTEZ                  #
#############################

@test "Scripts manejan errores correctamente" {
    # Probar con host inválido
    export HOSTS="invalid.domain.test"
    export PORTS="80"
    export TIMEOUT_SEC="2"
    
    run timeout 15 ./src/probe_tcp.sh
    [ "$status" -eq 0 ]  # No debe crashear
    [ -f "out/tcp_probes.csv" ]
}