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
    
    # Verificar header
    header=$(head -n1 out/test/tcp_probes.csv)
    [[ "$header" == "timestamp,host,port,status,latency_ms,socket_state" ]]
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
