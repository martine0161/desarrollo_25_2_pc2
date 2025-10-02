#!/usr/bin/env bats

# Arrange-Act-Assert para caso básico
@test "probe_tcp.sh debe generar CSV con headers correctos" {
    # Arrange
    export HOSTS="google.com"
    export PORTS="80"
    export OUTPUT_DIR="out/test"
    
    # Act
    run ./src/probe_tcp.sh
    
    # Assert
    [ "$status" -eq 0 ]
    [ -f "out/test/tcp_probes.csv" ]
    
    # Verificar header - CORREGIDO para incluir failure_reason
    header=$(head -n1 out/test/tcp_probes.csv)
    [[ "$header" == "timestamp,host,port,status,latency_ms,socket_state,failure_reason" ]]
}

@test "puerto abierto debe reportar status OPEN" {
    # Arrange
    export HOSTS="google.com"
    export PORTS="80"
    export OUTPUT_DIR="out/test_open"
    
    # Act
    run ./src/probe_tcp.sh
    
    # Assert
    [ "$status" -eq 0 ]
    
    # Verificar que contiene OPEN
    run grep "OPEN" out/test_open/tcp_probes.csv
    [ "$status" -eq 0 ]
}

@test "puerto cerrado debe reportar status CLOSED" {
    # Usar puerto probablemente cerrado
    export HOSTS="google.com"
    export PORTS="9999"
    export OUTPUT_DIR="out/test_closed"
    
    run ./src/probe_tcp.sh
    [ "$status" -eq 0 ]
    
    run grep "CLOSED" out/test_closed/tcp_probes.csv
    [ "$status" -eq 0 ]
}

@test "timeout debe manejarse correctamente" {
    export HOSTS="10.255.255.1"  # IP no ruteable
    export PORTS="80"
    export TIMEOUT_SEC="1"
    export OUTPUT_DIR="out/test_timeout"
    
    run timeout 10 ./src/probe_tcp.sh
    [ "$status" -eq 0 ]
}