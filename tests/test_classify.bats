#!/usr/bin/env bats

setup() {
    # Definir directorios donde buscar los scripts 
    PROJECT_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
    export PROJECT_ROOT
    
    echo "PROJECT_ROOT: $PROJECT_ROOT" >&3
    
    SCRIPT_PATH="$PROJECT_ROOT/src/classify_failures.sh"
    export SCRIPT_PATH
    
    echo "SCRIPT_PATH: $SCRIPT_PATH" >&3
    
    # Verificar que el script existe
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "ERROR: Script no encontrado en $SCRIPT_PATH" >&2
        echo "Archivos en src/: $(ls -la $PROJECT_ROOT/src/ 2>/dev/null || echo 'Directorio src no existe')" >&2
        exit 1
    fi
    
    echo "Script encontrado, continuando..." >&3
    
    # Creaamos directorio temporal para pruebas
    TEST_DIR=$(mktemp -d)
    export TEST_DIR
    export OUTPUT_DIR="$TEST_DIR/output"
    
    echo "TEST_DIR: $TEST_DIR" >&3
}

teardown() {
    # Limpiar directorio temporal
    if [ -n "$TEST_DIR" ] && [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Función que inicia el test - DEBUG
run_script() {
    echo "Ejecutando: bash '$SCRIPT_PATH' $@" >&3
    run bash "$SCRIPT_PATH" "$@"
    echo "Status: $status" >&3
    echo "Output: $output" >&3
}

@test "classify_failures.sh es un archivo regular existe" {
    # Verifica que sea un archivo regular
    [ -f "$SCRIPT_PATH" ]

    # Verifica que el archivo se pueda leer
    [ -r "$SCRIPT_PATH" ]
}

@test "classify_failures.sh muestra información de uso" {
    # Verifica que show_help muestre la ayuda, verificando texto existente en salida 
    run_script help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Comandos disponibles:"* ]]
}

@test "classify_failures.sh sin parámetros muestra error" {
    # Verifica que si no se agrega parametro requerido termine con error.
    run_script dns_check
    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR: No se proporcionaron los parámetros requeridos"* ]]
}

@test "classify_failures.sh crea un directorio de salida" {
    # Verificamos que al ejecutar script, se haya generado directorio de salida
    run_script dns_check example.com 80 "$OUTPUT_DIR"
    [ "$status" -eq 0 ]
    [ -d "$OUTPUT_DIR" ]
}

@test "classify_failures.sh crea archivos CSV con encabezados" {
    run_script dns_check example.com 80 "$OUTPUT_DIR"
    [ "$status" -eq 0 ]
    [ -f "$OUTPUT_DIR/nc_result.csv" ]
    [ -f "$OUTPUT_DIR/raw_result.csv" ]
    
    run head -1 "$OUTPUT_DIR/nc_result.csv"
    [[ "$output" == "timestamp, host, port, cause" ]]
    
    run head -1 "$OUTPUT_DIR/raw_result.csv"
    [[ "$output" == "timestamp, host, port, output" ]]
}

@test "classify_failures.sh help funciona" {
    # valida que help se ejecute sin errores
    run_script help
    [ "$status" -eq 0 ]
}