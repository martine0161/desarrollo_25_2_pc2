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

# Ayuda
.PHONY: help
help: ## Muestra los targets disponibles para el proyecto
	@echo "Make targets:"
	@grep -E '^[a-zA-Z0-9_\-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'

# Verificación de conectividad (conexiones salientes) con NC

# Verifica resolución de DNS
.PHONY: dns_check
dns_check: ## Verifica resolución de DNS generando bitacora de resultados
	@echo "Prueba de resolución de DNS"
	@./$(SRC_DIR)/classify_failures.sh dns_check $(HOST) $(PORT) ./$(OUT_DIR)
