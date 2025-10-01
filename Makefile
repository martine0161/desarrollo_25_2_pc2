.PHONY: tools build test run clean help

# Variables
OUTPUT_DIR = out
SRC_DIR = src

tools: ## Verificar herramientas disponibles
	@echo "Verificando herramientas..."
	@which nc || (echo "ERROR: nc no disponible" && exit 1)
	@which ss || (echo "ERROR: ss no disponible" && exit 1)
	@which bats || (echo "WARN: bats no disponible para pruebas")

build: tools ## Generar artefactos base
	@echo "Preparando directorio de salida..."
	@mkdir -p $(OUTPUT_DIR)

test: build ## Ejecutar suite de pruebas
	@echo "Ejecutando pruebas..."
	@bats tests/

run: build ## Ejecutar sondeo TCP
	@echo "Ejecutando sondeo de puertos..."
	@./$(SRC_DIR)/probe_tcp.sh

clean: ## Limpiar artefactos
	@echo "Limpiando archivos generados..."
	@rm -rf $(OUTPUT_DIR)

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
