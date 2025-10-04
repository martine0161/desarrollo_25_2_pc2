# Makefile - Proyecto 4: Smoke de puertos con ss y nc + bitácora
# Estudiante 3: Automatización y Empaquetado

# Configuración básica
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Directorios del proyecto
SRC_DIR := src
TEST_DIR := tests
DOCS_DIR := docs
OUTPUT_DIR := out
DIST_DIR := dist
# Compatibilidad
OUT_DIR := out

# Metadatos del proyecto
PROJECT_NAME := tcp-smoke
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v1.0.0")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Variables de entorno con valores por defecto
HOSTS ?= localhost,google.com,github.com
PORTS ?= 22,80,443
TIMEOUT_SEC ?= 5
PORT ?= 80
HOST ?= db-beta.imaxempresarial.com
DATE ?= $(shell date +%d-%m-%y)
# Herramientas requeridas según el documento
REQUIRED_TOOLS := nc ss curl grep sed awk cut sort uniq tr bats

# Colores para mejor experiencia visual
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
CYAN := \033[0;36m
RED := \033[0;31m
NC := \033[0m

# Targets que no generan archivos
.PHONY: tools build test run pack clean help info metrics demonstrate-cache dns_check show_report

#########################################
# TARGETS OBLIGATORIOS SEGÚN DOCUMENTO #
#########################################

tools: ## Verificar disponibilidad de utilidades requeridas
	@echo -e "$(BLUE)Verificando herramientas requeridas...$(NC)"
	@missing="" ; \
	critical_missing="" ; \
	for tool in $(REQUIRED_TOOLS); do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo -e "$(GREEN)✓$(NC) $$tool disponible" ; \
		else \
			case $$tool in \
				nc|ss) \
					critical_missing="$$critical_missing $$tool" ; \
					echo -e "$(RED)✗$(NC) $$tool NO disponible (CRÍTICO)" ; \
					;; \
				bats) \
					missing="$$missing $$tool" ; \
					echo -e "$(YELLOW)⚠$(NC) $$tool NO disponible (opcional para pruebas)" ; \
					;; \
				*) \
					missing="$$missing $$tool" ; \
					echo -e "$(YELLOW)⚠$(NC) $$tool NO disponible" ; \
					;; \
			esac ; \
		fi \
	done ; \
	if [ -n "$$critical_missing" ]; then \
		echo -e "$(RED)Herramientas críticas faltantes:$$critical_missing$(NC)" ; \
		echo "Instalar con: sudo apt-get install netcat-traditional iproute2" ; \
		exit 1 ; \
	fi ; \
	if [ -n "$$missing" ]; then \
		echo -e "$(YELLOW)Herramientas opcionales faltantes:$$missing$(NC)" ; \
	fi
	@echo -e "$(GREEN)Todas las herramientas críticas están disponibles$(NC)"

build: tools ## Generar artefactos intermedios en out/ (sin ejecutar)
	@echo -e "$(BLUE)Preparando entorno de construcción...$(NC)"
	@mkdir -p $(OUTPUT_DIR) $(DIST_DIR)
	@echo "$(PROJECT_NAME) $(VERSION)" > $(OUTPUT_DIR)/build.info
	@echo "Build time: $(BUILD_TIME)" >> $(OUTPUT_DIR)/build.info
	@echo "Variables: HOSTS=$(HOSTS), PORTS=$(PORTS), TIMEOUT_SEC=$(TIMEOUT_SEC)" >> $(OUTPUT_DIR)/build.info
	@echo "Host específico: HOST=$(HOST), PORT=$(PORT)" >> $(OUTPUT_DIR)/build.info
	@echo -e "$(GREEN)✓$(NC) Directorios creados: $(OUTPUT_DIR)/, $(DIST_DIR)/"
	@echo -e "$(BLUE)Verificando sintaxis de scripts...$(NC)"
	@errors=0 ; \
	for script in $(SRC_DIR)/*.sh; do \
		if [ -f "$$script" ]; then \
			if bash -n "$$script"; then \
				echo -e "$(GREEN)✓$(NC) $$script sintaxis válida" ; \
				chmod +x "$$script" 2>/dev/null || true ; \
			else \
				echo -e "$(YELLOW)✗$(NC) Error de sintaxis en $$script" ; \
				errors=$$((errors + 1)) ; \
			fi \
		fi \
	done ; \
	if [ $$errors -gt 0 ]; then \
		echo -e "$(YELLOW)Build completado con $$errors advertencias$(NC)" ; \
	else \
		echo -e "$(GREEN)Build completado exitosamente$(NC)" ; \
	fi

test: build ## Ejecutar suite Bats (valida criterios mínimos)
	@echo -e "$(BLUE)Ejecutando suite de pruebas...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		export OUTPUT_DIR=$(OUTPUT_DIR) HOSTS=$(HOSTS) PORTS=$(PORTS) TIMEOUT_SEC=$(TIMEOUT_SEC) ; \
		if bats $(TEST_DIR)/; then \
			echo -e "$(GREEN)✓ Todas las pruebas pasaron$(NC)" ; \
		else \
			echo -e "$(YELLOW)Algunas pruebas fallaron$(NC)" ; \
			exit 1 ; \
		fi \
	else \
		echo -e "$(YELLOW)Bats no disponible, ejecutando verificación básica...$(NC)" ; \
		for script in $(SRC_DIR)/*.sh; do \
			if [ -f "$$script" ] && [ -x "$$script" ]; then \
				echo -e "$(GREEN)✓$(NC) $$script es ejecutable" ; \
			elif [ -f "$$script" ]; then \
				echo -e "$(YELLOW)⚠$(NC) $$script no es ejecutable" ; \
				chmod +x "$$script" ; \
			fi \
		done ; \
		echo -e "$(GREEN)Verificación básica completada$(NC)" ; \
	fi

run: build ## Ejecutar flujo principal (sondeo → clasificación → bitácora)
	@echo -e "$(BLUE)Ejecutando flujo completo de TCP smoke tests...$(NC)"
	@echo "Variables activas: HOSTS=$(HOSTS), PORTS=$(PORTS), TIMEOUT_SEC=$(TIMEOUT_SEC)"
	@export HOSTS=$(HOSTS) PORTS=$(PORTS) TIMEOUT_SEC=$(TIMEOUT_SEC) OUTPUT_DIR=$(OUTPUT_DIR) ; \
	echo -e "$(CYAN)Paso 1: Sondeo de puertos TCP$(NC)" ; \
	if [ -x "$(SRC_DIR)/probe_tcp.sh" ]; then \
		if $(SRC_DIR)/probe_tcp.sh; then \
			echo -e "$(GREEN)✓ Sondeo completado$(NC)" ; \
		else \
			echo -e "$(YELLOW)✗ Error en sondeo TCP$(NC)" ; \
		fi \
	else \
		echo -e "$(YELLOW)⚠ probe_tcp.sh no encontrado o no ejecutable$(NC)" ; \
	fi ; \
	echo -e "$(CYAN)Paso 2: Clasificación de fallos$(NC)" ; \
	if [ -x "$(SRC_DIR)/classify_failures.sh" ]; then \
		if $(SRC_DIR)/classify_failures.sh; then \
			echo -e "$(GREEN)✓ Clasificación completada$(NC)" ; \
		else \
			echo -e "$(YELLOW)✗ Error en clasificación$(NC)" ; \
		fi \
	else \
		echo -e "$(YELLOW)⚠ classify_failures.sh no encontrado$(NC)" ; \
	fi ; \
	echo -e "$(CYAN)Paso 3: Generación de bitácora$(NC)" ; \
	if [ -x "$(SRC_DIR)/generate_logbook.sh" ]; then \
		if $(SRC_DIR)/generate_logbook.sh; then \
			echo -e "$(GREEN)✓ Bitácora completada$(NC)" ; \
		else \
			echo -e "$(YELLOW)✗ Error en bitácora$(NC)" ; \
		fi \
	else \
		echo -e "$(YELLOW)⚠ generate_logbook.sh no encontrado$(NC)" ; \
	fi
	@echo -e "$(GREEN)Flujo ejecutado. Resultados en $(OUTPUT_DIR)/$(NC)"

# Verificación de conectividad específica
dns_check: ## Verifica resolución de DNS generando bitacora de resultados
	@echo -e "$(BLUE)Prueba de resolución de DNS específica...$(NC)"
	@echo "Host: $(HOST), Puerto: $(PORT)"
	@if [ -x "$(SRC_DIR)/classify_failures.sh" ]; then \
		$(SRC_DIR)/classify_failures.sh dns_check $(HOST) $(PORT) ./$(OUTPUT_DIR) ; \
		echo -e "$(GREEN)✓ Prueba DNS completada$(NC)" ; \
	else \
		echo -e "$(YELLOW)⚠ classify_failures.sh no disponible$(NC)" ; \
		@echo "Resolución DNS básica para $(HOST):" ; \
		nslookup $(HOST) 2>/dev/null && echo -e "$(GREEN)✓ DNS resuelve$(NC)" || echo -e "$(RED)✗ DNS falla$(NC)" ; \
	fi

show_report: ## Muestra reporte de resultados para dns_check
	@echo -e "$(BLUE)Reporte de resultados de dns_check$(NC)"
	@if [ -x "$(SRC_DIR)/classify_failures.sh" ]; then \
		$(SRC_DIR)/classify_failures.sh show_report ./$(OUTPUT_DIR) ; \
	else \
		echo -e "$(YELLOW)Script de reporte no disponible$(NC)" ; \
		if [ -f "$(OUTPUT_DIR)/dns_check.log" ]; then \
			cat $(OUTPUT_DIR)/dns_check.log ; \
		else \
			echo "No hay reportes disponibles" ; \
		fi \
	fi

dns_check_all: ## Verifica DNS para múltiples hosts y puertos
	@echo -e "$(BLUE)Prueba de resolución de DNS para múltiples hosts y puertos...$(NC)"
	$(foreach host,$(shell echo "$(HOSTS)" | tr ',' ' '), \
		$(foreach port,$(shell echo "$(PORTS)" | tr ',' ' '), \
			echo "=== Probando $(host):$(port) ===" ; \
			$(MAKE) --no-print-directory dns_check HOST=$(host) PORT=$(port) ; \
			echo "" ; \
		) \
	)

.PHONY: generate_report_dns
generate_report_dns: show_report ## Genera reporte para pruebas de DNS realizadas, Args: [DATE] [LIST_HOSTS]
	@echo "Reporte de pruebas DNS el $(DATE)"
	@$(call check_format_date,$(DATE))
	@if [ -n "$(LIST_HOSTS)" ]; then \
    ./$(SRC_DIR)/generate_logbook.sh --reporte ./$(OUT_DIR)/nc_result.csv $(DATE) "$(HOSTS)"; \
	else \
			./$(SRC_DIR)/generate_logbook.sh --reporte ./$(OUT_DIR)/nc_result.csv $(DATE); \
	fi

pack: test ## Crear paquete reproducible en dist/ (nomenclatura con RELEASE)
	@echo -e "$(BLUE)Creando paquete reproducible...$(NC)"
	@mkdir -p $(DIST_DIR)
	@temp_dir=$$(mktemp -d) ; \
	package_name="$(PROJECT_NAME)-$(VERSION)" ; \
	package_dir="$$temp_dir/$$package_name" ; \
	mkdir -p "$$package_dir" ; \
	echo -e "$(CYAN)Copiando archivos...$(NC)" ; \
	cp -r $(SRC_DIR) $(TEST_DIR) $(DOCS_DIR) Makefile "$$package_dir/" 2>/dev/null || true ; \
	if [ -d "systemd" ]; then cp -r systemd "$$package_dir/" 2>/dev/null || true ; fi ; \
	echo "$$package_name" > "$$package_dir/VERSION" ; \
	echo "Build time: $(BUILD_TIME)" >> "$$package_dir/VERSION" ; \
	echo "Variables: HOSTS=$(HOSTS), PORTS=$(PORTS)" >> "$$package_dir/VERSION" ; \
	echo -e "$(CYAN)Generando checksums...$(NC)" ; \
	cd "$$package_dir" && find . -type f -exec sha256sum {} \; > CHECKSUMS ; \
	echo -e "$(CYAN)Comprimiendo...$(NC)" ; \
	cd "$$temp_dir" && tar -czf "$(CURDIR)/$(DIST_DIR)/$$package_name.tar.gz" "$$package_name" ; \
	rm -rf "$$temp_dir"
	@echo -e "$(GREEN)✓ Paquete creado: $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz$(NC)"
	@ls -lh $(DIST_DIR)/$(PROJECT_NAME)-$(VERSION).tar.gz

clean: ## Borrar out/ y dist/ de forma segura
	@echo -e "$(BLUE)Limpiando artefactos generados...$(NC)"
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		echo -e "$(CYAN)Removiendo $(OUTPUT_DIR)/$(NC)" ; \
		rm -rf $(OUTPUT_DIR) ; \
	fi
	@if [ -d "$(DIST_DIR)" ]; then \
		echo -e "$(CYAN)Removiendo $(DIST_DIR)/$(NC)" ; \
		rm -rf $(DIST_DIR) ; \
	fi
	@echo -e "$(GREEN)✓ Limpieza completada$(NC)"

help: ## Describir uso de cada target
	@echo -e "$(BLUE)$(PROJECT_NAME) - TCP Smoke Tests$(NC)"
	@echo "Proyecto 4: Smoke de puertos con ss y nc + bitácora"
	@echo ""
	@echo -e "$(BLUE)Uso: make [TARGET] [VARIABLES]$(NC)"
	@echo ""
	@echo -e "$(BLUE)Targets disponibles:$(NC)"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(BLUE)Variables de entorno (12-Factor):$(NC)"
	@echo "  HOSTS=$(HOSTS) (múltiples hosts)"
	@echo "  PORTS=$(PORTS) (múltiples puertos)" 
	@echo "  TIMEOUT_SEC=$(TIMEOUT_SEC)"
	@echo "  HOST=$(HOST) (host específico)"
	@echo "  PORT=$(PORT) (puerto específico)"
	@echo ""
	@echo -e "$(BLUE)Ejemplos:$(NC)"
	@echo "  make run HOSTS=google.com,localhost PORTS=80,443"
	@echo "  make dns_check HOST=example.com PORT=80"
	@echo "  make demonstrate-cache"
	@echo "  make pack"

install-systemd: ## Instalar servicio systemd (requiere sudo)
	@echo -e "$(BLUE)Instalando servicio systemd...$(NC)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo -e "$(YELLOW)Este comando requiere sudo$(NC)" ; \
		echo "Ejecutar: sudo make install-systemd" ; \
		exit 1 ; \
	fi
	cp systemd/tcp-monitor.service /etc/systemd/system/
	systemctl daemon-reload
	@echo -e "$(GREEN)✓ Servicio instalado$(NC)"
	@echo "Habilitar: sudo systemctl enable tcp-monitor.service"
	@echo "Iniciar: sudo systemctl start tcp-monitor.service"

uninstall-systemd: ## Desinstalar servicio systemd (requiere sudo)
	@echo -e "$(BLUE)Desinstalando servicio systemd...$(NC)"
	@if [ "$$(id -u)" -ne 0 ]; then \
		echo -e "$(YELLOW)Este comando requiere sudo$(NC)" ; \
		exit 1 ; \
	fi
	systemctl stop tcp-monitor.service 2>/dev/null || true
	systemctl disable tcp-monitor.service 2>/dev/null || true
	rm -f /etc/systemd/system/tcp-monitor.service
	systemctl daemon-reload
	@echo -e "$(GREEN)✓ Servicio desinstalado$(NC)"
	
###############################
# TARGETS ADICIONALES ÚTILES #
###############################

info: ## Mostrar información del proyecto
	@echo -e "$(BLUE)Información del Proyecto$(NC)"
	@echo "Nombre: $(PROJECT_NAME)"
	@echo "Versión: $(VERSION)"
	@echo "Build time: $(BUILD_TIME)"
	@echo ""
	@echo -e "$(BLUE)Variables actuales:$(NC)"
	@echo "HOSTS: $(HOSTS)"
	@echo "PORTS: $(PORTS)"
	@echo "TIMEOUT_SEC: $(TIMEOUT_SEC)"
	@echo "HOST específico: $(HOST)"
	@echo "PORT específico: $(PORT)"
	@echo "OUTPUT_DIR: $(OUTPUT_DIR)"
	@echo "DIST_DIR: $(DIST_DIR)"

metrics: ## Mostrar métricas básicas del proyecto
	@echo -e "$(BLUE)Métricas del Proyecto$(NC)"
	@echo "Scripts: $$(find $(SRC_DIR) -name "*.sh" 2>/dev/null | wc -l || echo 0)"
	@echo "Tests: $$(find $(TEST_DIR) -name "*.bats" 2>/dev/null | wc -l || echo 0)"
	@echo "Docs: $$(find $(DOCS_DIR) -name "*.md" 2>/dev/null | wc -l || echo 0)"
	@if [ -d "$(SRC_DIR)" ]; then \
		lines=$$(find $(SRC_DIR) -name "*.sh" -exec cat {} + 2>/dev/null | wc -l || echo 0) ; \
		echo "Líneas de código: $$lines" ; \
	fi

###################################
# REGLAS PATRÓN Y CACHÉ INCREMENTAL #
###################################
define check_format_date
	@if ! echo $1 | grep -Eq '^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{2}$$'; then \
		echo "Formato de fecha inválido:$1"; \
		echo "Ingrese en formato dd-mm-yy (01-05-25)"; \
		exit 1; \
	fi
endef

# Regla patrón: transformar CSV a texto tabulado
$(OUTPUT_DIR)/%.txt: $(OUTPUT_DIR)/%.csv
	@echo -e "$(CYAN)Transformando $< a $@$(NC)"
	@awk -F',' 'BEGIN{OFS="\t"} {$$1=$$1; print}' $< > $@

# Caché incremental para sondeo TCP (evidenciable con tiempos)
$(OUTPUT_DIR)/tcp_probes.csv: $(SRC_DIR)/probe_tcp.sh | build
	@if [ -f "$@" ] && [ "$@" -nt "$<" ]; then \
		echo -e "$(GREEN)✓ $@ está actualizado (caché hit)$(NC)" ; \
	else \
		echo -e "$(CYAN)Ejecutando sondeo TCP (caché miss)$(NC)" ; \
		export HOSTS=$(HOSTS) PORTS=$(PORTS) TIMEOUT_SEC=$(TIMEOUT_SEC) OUTPUT_DIR=$(OUTPUT_DIR) ; \
		$(SRC_DIR)/probe_tcp.sh ; \
	fi

# Caché incremental para clasificación
$(OUTPUT_DIR)/failure_classification.csv: $(SRC_DIR)/classify_failures.sh $(OUTPUT_DIR)/tcp_probes.csv
	@if [ -f "$@" ] && [ "$@" -nt "$(word 2,$^)" ]; then \
		echo -e "$(GREEN)✓ Clasificación actualizada (caché hit)$(NC)" ; \
	else \
		echo -e "$(CYAN)Ejecutando clasificación (caché miss)$(NC)" ; \
		export INPUT_FILE="$(OUTPUT_DIR)/tcp_probes.csv" OUTPUT_DIR=$(OUTPUT_DIR) ; \
		$(SRC_DIR)/classify_failures.sh ; \
	fi

# Target para demostrar caché incremental (evidenciable con time)
demonstrate-cache: $(OUTPUT_DIR)/tcp_probes.csv ## Demostrar caché incremental evidenciable
	@echo -e "$(BLUE)Demostrando caché incremental...$(NC)"
	@echo "Primera ejecución (debería tardar más):"
	@time $(MAKE) $(OUTPUT_DIR)/tcp_probes.csv HOSTS=google.com PORTS=80
	@sleep 1
	@echo ""
	@echo "Segunda ejecución (debería usar caché y ser más rápida):"
	@time $(MAKE) $(OUTPUT_DIR)/tcp_probes.csv HOSTS=google.com PORTS=80
	@echo ""
	@echo -e "$(GREEN)✓ Caché incremental evidenciado$(NC)"