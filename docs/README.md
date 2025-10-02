# TCP Smoke Tests - Proyecto 4
## Smoke de puertos con ss y nc + bitácora

Herramienta de verificación rápida de puertos TCP con clasificación automática de fallos y generación de bitácora operativa.

---

## Uso Básico

```bash
# Verificar herramientas disponibles
make tools

# Ejecutar flujo completo con configuración por defecto
make run

# Ejecutar con parámetros específicos
make run HOSTS=google.com,localhost PORTS=80,443,22 TIMEOUT_SEC=3

# Ejecutar suite de pruebas
make test

# Crear paquete para distribución
make pack

# Limpiar artefactos generados
make clean
```

---

## Variables de Entorno (12-Factor III)

| Variable | Efecto Observable | Verificación | Default |
|----------|-------------------|--------------|---------|
| `HOSTS` | Define hosts a probar | `echo $HOSTS` | localhost,google.com,github.com |
| `PORTS` | Puertos a verificar | `echo $PORTS` | 22,80,443 |
| `TIMEOUT_SEC` | Timeout para conexiones TCP | Tiempo de ejecución | 5 |
| `OUTPUT_DIR` | Directorio de salidas | `ls $OUTPUT_DIR` | out |
| `VERBOSE` | Nivel de logging | Cantidad de output | false |

### Ejemplos de configuración:
```bash
# Prueba rápida solo Google
export HOSTS="google.com"
export PORTS="80,443"
export TIMEOUT_SEC="2"
make run

# Auditoría completa de infraestructura local
export HOSTS="localhost,192.168.1.1,gateway.local"
export PORTS="22,80,443,8080,9090"
export TIMEOUT_SEC="10"
make run
```

---

## Automatización con Makefile

### Targets Obligatorios

| Target | Descripción | Ejemplo |
|--------|-------------|---------|
| `tools` | Verificar herramientas disponibles | `make tools` |
| `build` | Generar artefactos intermedios | `make build` |
| `test` | Ejecutar suite Bats | `make test` |
| `run` | Flujo principal (sondeo → clasificación → bitácora) | `make run` |
| `pack` | Crear paquete reproducible | `make pack` |
| `clean` | Limpiar out/ y dist/ | `make clean` |
| `help` | Mostrar ayuda completa | `make help` |

### Targets Adicionales

| Target | Descripción | Uso |
|--------|-------------|-----|
| `info` | Información del proyecto | `make info` |
| `metrics` | Estadísticas del código | `make metrics` |
| `demonstrate-cache` | Demostrar caché incremental | `make demonstrate-cache` |

### Caché Incremental (Evidenciable)

El Makefile implementa caché incremental basado en timestamps que evita rehacer trabajo innecesario:

```bash
# Primera ejecución (sin caché)
$ time make out/tcp_probes.csv
Ejecutando sondeo TCP (caché miss)
real    0m2.340s

# Segunda ejecución (con caché)
$ time make out/tcp_probes.csv
✓ out/tcp_probes.csv está actualizado (caché hit)
real    0m0.120s

# Mejora: ~20x más rápido
```

### Reglas Patrón

Transformaciones automáticas incluidas:

```bash
# Convertir CSV a formato tabulado automáticamente
make out/tcp_probes.txt  # Genera desde out/tcp_probes.csv

# La regla patrón:
# $(OUTPUT_DIR)/%.txt: $(OUTPUT_DIR)/%.csv
#     @awk -F',' 'BEGIN{OFS="\t"} {$$1=$$1; print}' $< > $@
```

---

## Flujo de Trabajo (12-Factor V)

### Separación Compilar/Lanzar/Ejecutar

1. **Compilar** (`make build`):
   - Verifica herramientas disponibles
   - Valida sintaxis de scripts
   - Prepara directorios de salida
   - Genera metadatos de build

2. **Lanzar** (configuración):
   - Variables de entorno definidas
   - Parámetros específicos del entorno
   - Configuración de timeouts y targets

3. **Ejecutar** (`make run`):
   - Sondeo TCP con nc/ss
   - Clasificación de fallos con Unix toolkit
   - Generación de bitácora operativa

### Flujo Detallado

```
make run →
├── Paso 1: Sondeo TCP (src/probe_tcp.sh)
│   ├── Conectividad con nc
│   ├── Estado de sockets con ss
│   └── Genera: out/tcp_probes.csv
│
├── Paso 2: Clasificación (src/classify_failures.sh)
│   ├── Analiza patrones de fallo
│   ├── Aplica reglas de clasificación
│   └── Genera: out/failure_classification.csv
│
└── Paso 3: Bitácora (src/generate_logbook.sh)
    ├── Consolida resultados
    ├── Genera recomendaciones
    └── Genera: out/operational_logbook.txt
```

---

## Contrato de Salidas

### Archivos Generados en out/

| Archivo | Formato | Descripción | Validación |
|---------|---------|-------------|------------|
| `build.info` | Texto | Metadatos de construcción | `grep "tcp-smoke" out/build.info` |
| `tcp_probes.csv` | CSV | Resultados de sondeo TCP | `grep "timestamp" out/tcp_probes.csv` |
| `failure_classification.csv` | CSV | Clasificación de fallos | `grep "failure_type" out/failure_classification.csv` |
| `operational_logbook.txt` | Texto | Bitácora operativa | `grep "ANÁLISIS" out/operational_logbook.txt` |

### Formato de tcp_probes.csv
```csv
timestamp,host,port,status,latency_ms,socket_state
2024-01-17 14:30:15,google.com,80,OPEN,45,N/A
2024-01-17 14:30:16,localhost,22,OPEN,2,LISTEN
2024-01-17 14:30:17,google.com,9999,CLOSED,N/A,N/A
```

### Formato de failure_classification.csv
```csv
host,port,original_status,failure_type,recommendation
google.com,80,OPEN,SUCCESS,Puerto accesible - OK
google.com,9999,CLOSED,PORT_CLOSED,Verificar si servicio está corriendo
invalid.host,80,CLOSED,DNS_FAILURE,Resolver problemas de DNS
```

---

## Pruebas Automatizadas

### Suite Bats (17 pruebas)

```bash
# Ejecutar todas las pruebas
make test

# Ejecutar directamente con bats
bats tests/test_integration.bats

# Resultados esperados:
17 tests, 0 failures (100% éxito)
```

### Categorías de pruebas:
- **Targets obligatorios** (6 tests): tools, build, test, run, pack, clean
- **Flujo de integración** (2 tests): end-to-end y generación de artefactos
- **Caché incremental** (2 tests): funcionamiento y demostración
- **Reglas patrón** (1 test): transformación CSV → TXT
- **Targets adicionales** (2 tests): info y metrics
- **Robustez** (3 tests): variables, scripts faltantes, reproducibilidad
- **Validación final** (1 test): estructura mínima requerida

---

## Empaquetado y Distribución

### Crear Paquete Reproducible

```bash
make pack
# Genera: dist/tcp-smoke-v1.0.0.tar.gz

# Contenido del paquete:
tar -tzf dist/tcp-smoke-v1.0.0.tar.gz
# tcp-smoke-v1.0.0/
# ├── Makefile
# ├── VERSION
# ├── CHECKSUMS
# ├── src/
# ├── tests/
# ├── docs/
# └── scripts/
```

### Verificación de Integridad

```bash
# Extraer y verificar checksums
tar -xzf dist/tcp-smoke-v1.0.0.tar.gz
cd tcp-smoke-v1.0.0
sha256sum -c CHECKSUMS
```

---

## Monitoreo con systemd (Opcional)

### Instalación como Servicio

```bash
# Instalar unidad systemd (requiere sudo)
sudo make install-systemd

# Habilitar y iniciar
sudo systemctl enable tcp-monitor.service
sudo systemctl start tcp-monitor.service

# Verificar estado
systemctl status tcp-monitor.service

# Ver logs
journalctl -u tcp-monitor.service -f
```

### Desinstalación

```bash
sudo make uninstall-systemd
```

---

## Troubleshooting

### Problemas Comunes

**Error: "nc: command not found"**
```bash
# Ubuntu/Debian
sudo apt-get install netcat-traditional

# Verificar instalación
make tools
```

**Error: "Bats no disponible"**
```bash
# El Makefile incluye fallback automático
make test  # Usará verificación básica

# Para instalar bats:
sudo apt-get install bats
```

**Error: "Permission denied" en scripts**
```bash
# El Makefile corrige automáticamente
make build  # Añade permisos +x a scripts
```

**Caché no funciona correctamente**
```bash
# Verificar timestamps
ls -la --time-style=full-iso out/ src/

# Limpiar y probar
make clean && make demonstrate-cache
```

### Debugging

```bash
# Modo verbose
export VERBOSE=true
make run

# Validar integración
./scripts/validate_integration.sh

# Información del proyecto
make info

# Métricas de código
make metrics
```

---

## Principios Aplicados

### 12-Factor App
- **I. Codebase**: Una base de código única rastreada en Git
- **III. Config**: Configuración vía variables de entorno
- **V. Build/Release/Run**: Separación clara de etapas

### CALMS
- **Culture**: Colaboración entre 3 estudiantes
- **Automation**: Makefile con targets automatizados
- **Lean**: Flujo eficiente sin pasos innecesarios
- **Measurement**: Métricas de rendimiento evidenciables
- **Sharing**: Documentación compartida y reproducible

### You Build It You Run It (YBIYRI)
- El mismo equipo construye, prueba y opera la herramienta
- Documentación operativa integrada
- Responsabilidad end-to-end del ciclo de vida

---

## Desarrollo y Contribución

### Estructura del Proyecto
```
├── Makefile              # Automatización principal
├── src/                  # Scripts principales
├── tests/                # Suite de pruebas Bats
├── docs/                 # Documentación y bitácoras
├── scripts/              # Utilidades de validación
├── out/                  # Salidas (ignorado en git)
└── dist/                 # Paquetes (ignorado en git)
```

### Workflow de Desarrollo
1. Modificar scripts en `src/`
2. Ejecutar `make test` para validar
3. Probar con `make run`
4. Documentar cambios en bitácoras
5. Crear paquete con `make pack`

---

**Para más información detallada, consultar las bitácoras de sprint en docs/**