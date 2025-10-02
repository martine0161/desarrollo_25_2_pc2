#!/usr/bin/env bats
# test_integration.bats - Suite de pruebas de integración
# Estudiante 3: Automatización y Empaquetado

# Variables globales para las pruebas
TEST_OUTPUT_DIR="out/integration_test"
TEST_DIST_DIR="dist/integration_test"

# Setup ejecutado antes de cada test
setup() {
    # Limpiar y crear directorios de prueba
    rm -rf "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR" 2>/dev/null || true
    mkdir -p "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR"
    
    # Variables de entorno para pruebas
    export OUTPUT_DIR="$TEST_OUTPUT_DIR"
    export DIST_DIR="$TEST_DIST_DIR"
    export HOSTS="google.com,localhost"
    export PORTS="80,22"
    export TIMEOUT_SEC="3"
}

# Teardown ejecutado después de cada test
teardown() {
    # Limpiar solo si el test completó exitosamente
    if [ "${BATS_TEST_COMPLETED}" ]; then
        rm -rf "$TEST_OUTPUT_DIR" "$TEST_DIST_DIR" 2>/dev/null || true
    fi
}

#############################
# TARGETS OBLIGATORIOS      #
#############################

@test "make tools debe verificar herramientas sin errores" {
    run make tools
    [ "$status" -eq 0 ]
    [[ "$output" =~ "nc" ]]
    [[ "$output" =~ "ss" ]]
    [[ "$output" =~ "curl" ]]
    [[ "$output" =~ "disponibles" ]]
}

@test "make build debe crear directorios y validar scripts" {
    run make build OUTPUT_DIR="$TEST_OUTPUT_DIR" DIST_DIR="$TEST_DIST_DIR"
    [ "$status" -eq 0 ]
    
    # Verificar directorios creados
    [ -d "$TEST_OUTPUT_DIR" ]
    [ -d "$TEST_DIST_DIR" ]
    
    # Verificar archivo de build info
    [ -f "$TEST_OUTPUT_DIR/build.info" ]
    grep -q "tcp-smoke" "$TEST_OUTPUT_DIR/build.info"
}

@test "make help debe mostrar todos los targets obligatorios" {
    run make help
    [ "$status" -eq 0 ]
    
    # Verificar targets obligatorios
    [[ "$output" =~ "tools" ]]
    [[ "$output" =~ "build" ]]
    [[ "$output" =~ "test" ]]
    [[ "$output" =~ "run" ]]
    [[ "$output" =~ "pack" ]]
    [[ "$output" =~ "clean" ]]
    [[ "$output" =~ "help" ]]
    
    # Verificar variables de entorno
    [[ "$output" =~ "HOSTS" ]]
    [[ "$output" =~ "PORTS" ]]
}

@test "make clean debe remover artefactos correctamente" {
    # Crear archivos para limpiar
    make build OUTPUT_DIR="$TEST_OUTPUT_DIR" DIST_DIR="$TEST_DIST_DIR"
    [ -d "$TEST_OUTPUT_DIR" ]
    
    # Ejecutar limpieza
    run make clean OUTPUT_DIR="$TEST_OUTPUT_DIR" DIST_DIR="$TEST_DIST_DIR"
    [ "$status" -eq 0 ]
    
    # Verificar que se eliminaron
    [ ! -d "$TEST_OUTPUT_DIR" ]
    [ ! -d "$TEST_DIST_DIR" ]
}

@test "make test debe ejecutar suite sin errores" {
    run make test OUTPUT_DIR="$TEST_OUTPUT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "pruebas" || "$output" =~ "verificación" ]]
}

@test "make pack debe crear paquete válido" {
    # Preparar entorno
    make build OUTPUT_DIR="$TEST_OUTPUT_DIR" DIST_DIR="$TEST_DIST_DIR"
    
    # Crear paquete
    run make pack DIST_DIR="$TEST_DIST_DIR" OUTPUT_DIR="$TEST_OUTPUT_DIR"
    [ "$status" -eq 0 ]
    
    # Verificar que existe paquete
    package_file=$(ls "$TEST_DIST_DIR"/tcp-smoke-*.tar.gz 2>/dev/null | head -1)
    [ -f "$package_file" ]
    
    # Verificar contenido básico
    tar -tzf "$package_file" | grep -q "Makefile"
    tar -tzf "$package_file" | grep -q "src/"
    tar -tzf "$package_file" | grep -q "VERSION"
    tar -tzf "$package_file" | grep -q "CHECKSUMS"
}

#############################
# FLUJO DE INTEGRACIÓN      #
#############################

@test "make run debe ejecutar flujo completo" {
    run make run OUTPUT_DIR="$TEST_OUTPUT_DIR"
    [ "$status" -eq 0 ]
    
    # Verificar que muestra los pasos
    [[ "$output" =~ "Paso 1" ]]
    [[ "$output" =~ "Paso 2" ]]
    [[ "$output" =~ "Paso 3" ]]
    [[ "$output" =~ "Flujo ejecutado" ]]
}

@test "flujo debe generar artefactos cuando scripts existen" {
    # Solo ejecutar si existe al menos probe_tcp.sh
    if [ ! -x "src/probe_tcp.sh" ]; then
        skip "Scripts no disponibles aún"
    fi
    
    export HOSTS="google.com"
    export PORTS="80"
    export OUTPUT_DIR="$TEST_OUTPUT_DIR"
    
    run make run
    [ "$status" -eq 0 ]
    
    # Verificar archivo principal
    [ -f "$TEST_OUTPUT_DIR/tcp_probes.csv" ]
    
    # Verificar formato básico
    head -1 "$TEST_OUTPUT_DIR/tcp_probes.csv" | grep -q "timestamp"
}

#############################
# CACHÉ INCREMENTAL         #
#############################

@test "caché incremental debe funcionar correctamente" {
    if [ ! -x "src/probe_tcp.sh" ]; then
        skip "probe_tcp.sh no disponible para prueba de caché"
    fi
    
    export OUTPUT_DIR="$TEST_OUTPUT_DIR"
    export HOSTS="google.com"
    export PORTS="80"
    
    # Primera ejecución
    start_time=$(date +%s)
    make "$TEST_OUTPUT_DIR/tcp_probes.csv"
    first_duration=$(($(date +%s) - start_time))
    
    [ -f "$TEST_OUTPUT_DIR/tcp_probes.csv" ]
    
    # Segunda ejecución (debería usar caché)
    start_time=$(date +%s)
    run make "$TEST_OUTPUT_DIR/tcp_probes.csv"
    second_duration=$(($(date +%s) - start_time))
    
    [ "$status" -eq 0 ]
    [[ "$output" =~ "caché hit" || "$output" =~ "actualizado" ]]
    
    # Segunda vez debería ser más rápida
    [ "$second_duration" -le $((first_duration + 1)) ]
}

@test "demonstrate-cache debe mostrar diferencias de tiempo" {
    if [ ! -x "src/probe_tcp.sh" ]; then
        skip "probe_tcp.sh no disponible"
    fi
    
    run make demonstrate-cache OUTPUT_DIR="$TEST_OUTPUT_DIR"
    [ "$status" -eq 0 ]
    
    # Verificar que muestra mediciones
    [[ "$output" =~ "Primera ejecución" ]]
    [[ "$output" =~ "Segunda ejecución" ]]
    [[ "$output" =~ "real" ]]
}

#############################
# REGLAS PATRÓN             #
#############################

@test "regla patrón CSV a TXT debe funcionar" {
    # Crear CSV de prueba
    echo "host,port,status" > "$TEST_OUTPUT_DIR/sample.csv"
    echo "google.com,80,OPEN" >> "$TEST_OUTPUT_DIR/sample.csv"
    echo "localhost,22,CLOSED" >> "$TEST_OUTPUT_DIR/sample.csv"
    
    # Aplicar regla patrón
    run make "$TEST_OUTPUT_DIR/sample.txt"
    [ "$status" -eq 0 ]
    
    # Verificar archivo generado
    [ -f "$TEST_OUTPUT_DIR/sample.txt" ]
    
    # Verificar que contiene tabs
    grep -q $'\t' "$TEST_OUTPUT_DIR/sample.txt"
}

#############################
# TARGETS ADICIONALES       #
#############################

@test "make info debe mostrar información del proyecto" {
    run make info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "tcp-smoke" ]]
    [[ "$output" =~ "Versión" ]]
    [[ "$output" =~ "HOSTS" ]]
    [[ "$output" =~ "PORTS" ]]
}

@test "make metrics debe mostrar estadísticas básicas" {
    run make metrics
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Scripts" ]]
    [[ "$output" =~ "Tests" ]]
    [[ "$output" =~ "Docs" ]]
}

#############################
# VALIDACIÓN Y ROBUSTEZ     #
#############################

@test "variables de entorno deben ser configurables" {
    export HOSTS="localhost"
    export PORTS="22,80"
    
    run make info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "localhost" ]]
    [[ "$output" =~ "22,80" ]]
}

@test "debe manejar scripts faltantes sin crashear" {
    # Renombrar temporalmente si existe
    if [ -f "src/probe_tcp.sh" ]; then
        mv "src/probe_tcp.sh" "src/probe_tcp.sh.bak"
    fi
    
    run make run OUTPUT_DIR="$TEST_OUTPUT_DIR"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "no encontrado" || "$output" =~ "no ejecutable" ]]
    
    # Restaurar
    if [ -f "src/probe_tcp.sh.bak" ]; then
        mv "src/probe_tcp.sh.bak" "src/probe_tcp.sh"
    fi
}

@test "paquete debe ser reproducible" {
    # Crear primer paquete
    make build OUTPUT_DIR="$TEST_OUTPUT_DIR"
    make pack DIST_DIR="$TEST_DIST_DIR/pack1" OUTPUT_DIR="$TEST_OUTPUT_DIR"
    
    # Crear segundo paquete
    make pack DIST_DIR="$TEST_DIST_DIR/pack2" OUTPUT_DIR="$TEST_OUTPUT_DIR"
    
    # Verificar que ambos existen
    package1=$(ls "$TEST_DIST_DIR/pack1/"*.tar.gz | head -1)
    package2=$(ls "$TEST_DIST_DIR/pack2/"*.tar.gz | head -1)
    
    [ -f "$package1" ]
    [ -f "$package2" ]
    
    # Verificar estructura idéntica
    diff <(tar -tzf "$package1" | sort) <(tar -tzf "$package2" | sort)
}

#############################
# VALIDACIÓN FINAL          #
#############################

@test "proyecto debe tener estructura mínima requerida" {
    # Verificar archivos esenciales
    [ -f "Makefile" ]
    [ -d "src" ]
    [ -d "tests" ]
    [ -d "docs" ]
    
    # Verificar targets en Makefile
    grep -q "^tools:" Makefile
    grep -q "^build:" Makefile
    grep -q "^test:" Makefile
    grep -q "^run:" Makefile
    grep -q "^pack:" Makefile
    grep -q "^clean:" Makefile
    grep -q "^help:" Makefile
}