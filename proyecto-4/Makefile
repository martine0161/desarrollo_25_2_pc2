# Variables de configuración
.DEFAULT_GOAL := help
SHELL := /bin/bash

# Directorios
SRC_DIR := src
TEST_DIR := tests
DOCS_DIR := docs
OUTPUT_DIR := out
DIST_DIR := dist
SYSTEMD_DIR := systemd

# Metadatos del proyecto
PROJECT_NAME := tcp-smoke
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "v1.0.0-dev")
RELEASE := $(shell echo $(VERSION) | sed 's/^v//')
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S_UTC')
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Colores para output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Herramientas requeridas
REQUIRED_TOOLS := nc ss curl grep sed awk cut sort uniq tr tee find
OPTIONAL_TOOLS := bats dig ssh scp rsync

.PHONY: tools build test run pack clean help info

tools: ## Verificar disponibilidad de herramientas necesarias
	@echo -e "$(BLUE)Verificando herramientas requeridas...$(NC)"
	@missing_tools="" ; \
	for tool in $(REQUIRED_TOOLS); do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			missing_tools="$$missing_tools $$tool" ; \
		else \
			echo -e "$(GREEN)✓$(NC) $$tool encontrado en $$(command -v $$tool)" ; \
		fi \
	done ; \
	if [ -n "$$missing_tools" ]; then \
		echo -e "$(RED)ERROR: Herramientas faltantes:$$missing_tools$(NC)" ; \
		exit 1 ; \
	fi
	@echo -e "$(BLUE)Verificando herramientas opcionales...$(NC)"
	@for tool in $(OPTIONAL_TOOLS); do \
		if command -v $$tool >/dev/null 2>&1; then \
			echo -e "$(GREEN)✓$(NC) $$tool disponible" ; \
		else \
			echo -e "$(YELLOW)⚠$(NC) $$tool no disponible (opcional)" ; \
		fi \
	done
	@echo -e "$(GREEN)Verificación de herramientas completada$(NC)"

build: tools ## Generar artefactos intermedios sin ejecutar
	@echo -e "$(BLUE)Preparando entorno de construcción...$(NC)"
	@mkdir -p $(OUTPUT_DIR) $(DIST_DIR)
	@echo -e "$(GREEN)✓$(NC) Directorios creados: $(OUTPUT_DIR)/, $(DIST_DIR)/"
	@echo "$(PROJECT_NAME)-$(VERSION)" > $(OUTPUT_DIR)/build.info
	@echo "Build time: $(BUILD_TIME)" >> $(OUTPUT_DIR)/build.info
	@echo "Git commit: $(GIT_COMMIT)" >> $(OUTPUT_DIR)/build.info
	@echo -e "$(GREEN)✓$(NC) Información de build guardada en $(OUTPUT_DIR)/build.info"
	@# Verificar integridad de scripts
	@echo -e "$(BLUE)Verificando integridad de scripts...$(NC)"
	@for script in $(SRC_DIR)/*.sh; do \
		if [ -f "$$script" ]; then \
			if bash -n "$$script"; then \
				echo -e "$(GREEN)✓$(NC) Sintaxis válida: $$script" ; \
			else \
				echo -e "$(RED)✗$(NC) Error de sintaxis: $$script" ; \
				exit 1 ; \
			fi \
		fi \
	done
	@echo -e "$(GREEN)Build completado$(NC)"

test: build ## Ejecutar suite de pruebas Bats
	@echo -e "$(BLUE)Ejecutando suite de pruebas...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		echo -e "$(CYAN)Ejecutando pruebas Bats...$(NC)" ; \
		bats $(TEST_DIR)/ || (echo -e "$(RED)Algunas pruebas fallaron$(NC)" && exit 1) ; \
		echo -e "$(GREEN)✓$(NC) Todas las pruebas pasaron" ; \
	else \
		echo -e "$(YELLOW)⚠$(NC) Bats no disponible, ejecutando verificación básica..." ; \
		$(MAKE) test-basic ; \
	fi

test-basic: ## Verificación básica sin Bats
	@echo -e "$(CYAN)Ejecutando verificación básica de scripts...$(NC)"
	@for script in $(SRC_DIR)/*.sh; do \
		if [ -f "$$script" ] && [ -x "$$script" ]; then \
			echo -e "$(BLUE)Probando: $$script$(NC)" ; \
			timeout 10s bash -c "$$script --help || true" || echo -e "$(YELLOW)Script no responde a --help$(NC)" ; \
		fi \
	done

run: build ## Ejecutar flujo principal del proyecto
	@echo -e "$(BLUE)Ejecutando flujo completo de TCP smoke tests...$(NC)"
	@echo -e "$(CYAN)Paso 1: Sondeo de puertos TCP$(NC)"
	@if [ -x "$(SRC_DIR)/probe_tcp.sh" ]; then \
		$(SRC_DIR)/probe_tcp.sh || (echo -e "$(RED)Error en sondeo TCP$(NC)" && exit 1) ; \
	else \
		echo -e "$(YELLOW)⚠$(NC) Script probe_tcp.sh no encontrado o no ejecutable" ; \
	fi
	@echo -e "$(CYAN)Paso 2: Clasificación de fallos$(NC)"
	@if [ -x "$(SRC_DIR)/classify_failures.sh" ]; then \
		$(SRC_DIR)/classify_failures.sh || (echo -e "$(RED)Error en clasificación$(NC)" && exit 1) ; \
	else \
		echo -e "$(YELLOW)⚠$(NC) Script classify_failures.sh no encontrado" ; \
	fi
	@echo -e "$(CYAN)Paso 3: Generación de bitácora$(NC)"
	@if [ -x "$(SRC_DIR)/generate_logbook.sh" ]; then \
		$(SRC_DIR)/generate_logbook.sh || (echo -e "$(RED)Error en bitácora$(NC)" && exit 1) ; \
	else \
		echo -e "$(YELLOW)⚠$(NC) Script generate_logbook.sh no encontrado" ; \
	fi
	@echo -e "$(GREEN)✓$(NC) Flujo completo ejecutado. Resultados en $(OUTPUT_DIR)/"

pack: test ## Crear paquete reproducible
	@echo -e "$(BLUE)Creando paquete $(PROJECT_NAME)-$(RELEASE)...$(NC)"
	@mkdir -p $(DIST_DIR)
	@# Crear estructura temporal para el paquete
	@temp_dir=$$(mktemp -d) ; \
	package_dir="$$temp_dir/$(PROJECT_NAME)-$(RELEASE)" ; \
	mkdir -p "$$package_dir" ; \
	echo -e "$(CYAN)Copiando archivos al paquete...$(NC)" ; \
	cp -r $(SRC_DIR) $(TEST_DIR) $(DOCS_DIR) Makefile "$$package_dir/" ; \
	if [ -d "$(SYSTEMD_DIR)" ]; then cp -r $(SYSTEMD_DIR) "$$package_dir/" ; fi ; \
	echo "$(PROJECT_NAME) $(VERSION)" > "$$package_dir/VERSION" ; \
	echo "Empaquetado: $(BUILD_TIME)" >> "$$package_dir/VERSION" ; \
	echo "Commit: $(GIT_COMMIT)" >> "$$package_dir/VERSION" ; \
	echo -e "$(CYAN)Generando checksums...$(NC)" ; \
	cd "$$package_dir" && find . -type f -exec sha256sum {} \; > CHECKSUMS ; \
	cd "$$temp_dir" && tar -czf "$(CURDIR)/$(DIST_DIR)/$(PROJECT_NAME)-$(RELEASE).tar.gz" "$(PROJECT_NAME)-$(RELEASE)" ; \
	rm -rf "$$temp_dir"
	@echo -e "$(GREEN)✓$(NC) Paquete creado: $(DIST_DIR)/$(PROJECT_NAME)-$(RELEASE).tar.gz"
	@ls -lh $(DIST_DIR)/$(PROJECT_NAME)-$(RELEASE).tar.gz

clean: ## Limpiar artefactos generados
	@echo -e "$(BLUE)Limpiando artefactos...$(NC)"
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		echo -e "$(CYAN)Removiendo $(OUTPUT_DIR)/$(NC)" ; \
		rm -rf $(OUTPUT_DIR) ; \
	fi
	@if [ -d "$(DIST_DIR)" ]; then \
		echo -e "$(CYAN)Removiendo $(DIST_DIR)/$(NC)" ; \
		rm -rf $(DIST_DIR) ; \
	fi
	@echo -e "$(GREEN)✓$(NC) Limpieza completada"

info: ## Mostrar información del proyecto
	@echo -e "$(PURPLE)Información del Proyecto$(NC)"
	@echo "Nombre: $(PROJECT_NAME)"
	@echo "Versión: $(VERSION)"
	@echo "Release: $(RELEASE)"
	@echo "Commit: $(GIT_COMMIT)"
	@echo "Build time: $(BUILD_TIME)"
	@echo ""
	@echo -e "$(PURPLE)Estructura del proyecto:$(NC)"
	@tree -I 'out|dist|.git' || find . -type d -not -path './.*' -not -path './out*' -not -path './dist*' | head -10

help: ## Mostrar esta ayuda
	@echo -e "$(PURPLE)$(PROJECT_NAME) - TCP Smoke Tests$(NC)"
	@echo "Uso: make [TARGET]"
	@echo ""
	@echo -e "$(BLUE)Targets disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "$(BLUE)Variables de entorno reconocidas:$(NC)"
	@echo "  HOSTS         - Lista de hosts a probar"
	@echo "  PORTS         - Lista de puertos a verificar"
	@echo "  TIMEOUT_SEC   - Timeout para conexiones"
	@echo "  OUTPUT_DIR    - Directorio de salidas"