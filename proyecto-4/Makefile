# Configuración básica del Makefile
.DEFAULT_GOAL := help    # Ejecutar 'help' cuando se corre solo 'make'
.SHELL := /bin/bash      # Sell a usar: Bash para mejor soporte de scripts

# Variables de proyecto (12-Factor)
PROJECT_NAME := proyecto-4
VERSION := v1
SRC_DIR := src
DOCS_DIR := docs
TEST_DIR := tests
OUT_DIR := out
DIST_DIR := dist

# Variables de entorno
PORT ?= 80
HOST ?= db-beta.imaxempresarial.com
DATE ?= $(shell date +%d-%m-%y)

define check_format_date
	@if ! echo $1 | grep -Eq '^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{2}$$'; then \
		echo "Formato de fecha inválido:$1"; \
		echo "Ingrese en formato dd-mm-yy (01-05-25)"; \
		exit 1; \
	fi
endef

# Ayuda
.PHONY: help
help: ## Muestra los targets disponibles para el proyecto
	@echo "Variables configurables:"
	@echo "  HOST=<hostname>    Servidor destino (default: $(HOST))"
	@echo "  PORT=<puerto>      Puerto destino (default: $(PORT))"
	@echo "  DATE=[fecha]       Fecha en formato dd-mm-yy (default: hoy)"
	@echo "  HOSTS=[lista]      Lista de hosts para filtrar reportes"
	@echo ""
	@echo "Targets disponibles:"
	@grep -E '^[a-zA-Z0-9_\-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# Verificación de conectividad (conexiones salientes) con NC

# Verifica resolución de DNS
.PHONY: dns_check
dns_check: ## Verifica resolución de DNS, Args: <HOST>, <PORT>
	@echo "Prueba de resolución de DNS"
	@./$(SRC_DIR)/classify_failures.sh dns_check $(HOST) $(PORT) ./$(OUT_DIR)

.PHONY: result_dns
result_dns: ## Muestra resultados de pruebas dns_check
	@echo "Resultados de dns_check"
	@./$(SRC_DIR)/classify_failures.sh show_report ./$(OUT_DIR)

.PHONY: generate_report_dns
generate_report_dns: ## Genera reporte para pruebas de DNS realizadas, Args: [DATE] [HOSTS]
	@echo "Reporte de pruebas DNS el $(DATE)"
	@$(call check_format_date,$(DATE))
	@if [ -n "$(HOSTS)" ]; then \
    ./$(SRC_DIR)/generate_logbook.sh --reporte ./$(OUT_DIR)/nc_result.csv $(DATE) "$(HOSTS)"; \
	else \
			./$(SRC_DIR)/generate_logbook.sh --reporte ./$(OUT_DIR)/nc_result.csv $(DATE); \
	fi

.PHONY: test_classify_failures
test_classify_failures: ## Ejecuta test con bats
	@echo "Iniciando test para classify_failures.sh"
	@bats $(TEST_DIR)/test_classify.bats