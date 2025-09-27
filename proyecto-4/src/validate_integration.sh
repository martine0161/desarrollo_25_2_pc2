#!/bin/bash
# validate_integration.sh - Validación de integración entre componentes
# Estudiante 3: Automatización y Empaquetado

set -euo pipefail

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== VALIDACIÓN DE INTEGRACIÓN ===${NC}"

# Scripts principales requeridos
REQUIRED_SCRIPTS=(
    "src/probe_tcp.sh"
    "src/classify_failures.sh"
    "src/generate_logbook.sh"
)

# Archivos de configuración importantes
REQUIRED_FILES=(
    "Makefile"
    "docs/README.md"
)

echo -e "${BLUE}1. Verificando scripts principales...${NC}"

missing_scripts=()
for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            echo -e "${GREEN}✓${NC} $script existe y es ejecutable"
        else
            echo -e "${YELLOW}⚠${NC} $script existe pero no es ejecutable, corrigiendo..."
            chmod +x "$script"
            echo -e "${GREEN}✓${NC} Permisos corregidos para $script"
        fi
    else
        missing_scripts+=("$script")
        echo -e "${YELLOW}⚠${NC} $script no encontrado"
    fi
done

if [[ ${#missing_scripts[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Scripts faltantes (normal en desarrollo):${NC}"
    printf '  - %s\n' "${missing_scripts[@]}"
else
    echo -e "${GREEN}✓ Todos los scripts principales están presentes${NC}"
fi

echo -e "${BLUE}2. Verificando archivos de configuración...${NC}"

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $file presente"
    else
        echo -e "${RED}✗${NC} $file faltante (requerido)"
    fi
done

echo -e "${BLUE}3. Verificando estructura de directorios...${NC}"

required_dirs=("src" "tests" "docs" "out" "dist")
for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} Directorio $dir/ existe"
    else
        echo -e "${YELLOW}⚠${NC} Directorio $dir/ no existe, creando..."
        mkdir -p "$dir"
        echo -e "${GREEN}✓${NC} Directorio $dir/ creado"
    fi
done

echo -e "${BLUE}4. Verificando Makefile...${NC}"

if [[ -f "Makefile" ]]; then
    # Verificar targets obligatorios
    obligatory_targets=("tools" "build" "test" "run" "pack" "clean" "help")
    missing_targets=()
    
    for target in "${obligatory_targets[@]}"; do
        if grep -q "^${target}:" Makefile; then
            echo -e "${GREEN}✓${NC} Target '$target' presente en Makefile"
        else
            missing_targets+=("$target")
        fi
    done
    
    if [[ ${#missing_targets[@]} -gt 0 ]]; then
        echo -e "${RED}✗${NC} Targets faltantes en Makefile:"
        printf '  - %s\n' "${missing_targets[@]}"
    else
        echo -e "${GREEN}✓ Todos los targets obligatorios están presentes${NC}"
    fi
else
    echo -e "${RED}✗${NC} Makefile no encontrado"
fi

echo -e "${BLUE}5. Verificando respuesta a --help de scripts...${NC}"

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [[ -x "$script" ]]; then
        if timeout 5s "$script" --help >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} $script responde a --help"
        else
            echo -e "${YELLOW}⚠${NC} $script no responde a --help (opcional)"
        fi
    fi
done

echo -e "${BLUE}6. Probando Makefile básico...${NC}"

if [[ -f "Makefile" ]]; then
    # Probar target tools
    if make tools >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} 'make tools' funciona"
    else
        echo -e "${YELLOW}⚠${NC} 'make tools' falló (puede necesitar herramientas)"
    fi
    
    # Probar target help
    if make help >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} 'make help' funciona"
    else
        echo -e "${RED}✗${NC} 'make help' falló"
    fi
    
    # Probar target build
    if make build >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} 'make build' funciona"
        # Limpiar después de la prueba
        make clean >/dev/null 2>&1 || true
    else
        echo -e "${YELLOW}⚠${NC} 'make build' falló"
    fi
fi

echo -e "${BLUE}7. Verificando integración de variables de entorno...${NC}"

# Probar algunas variables importantes
test_vars=("HOSTS" "PORTS" "TIMEOUT_SEC" "OUTPUT_DIR")
for var in "${test_vars[@]}"; do
    if grep -q "$var" Makefile 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Variable $var está en Makefile"
    else
        echo -e "${YELLOW}⚠${NC} Variable $var no encontrada en Makefile"
    fi
done

echo -e "${BLUE}8. Resumen de validación...${NC}"

# Contar elementos presentes
scripts_present=0
for script in "${REQUIRED_SCRIPTS[@]}"; do
    [[ -f "$script" ]] && ((scripts_present++))
done

files_present=0
for file in "${REQUIRED_FILES[@]}"; do
    [[ -f "$file" ]] && ((files_present++))
done

echo "Scripts presentes: $scripts_present/${#REQUIRED_SCRIPTS[@]}"
echo "Archivos config presentes: $files_present/${#REQUIRED_FILES[@]}"

# Determinar estado general
if [[ $scripts_present -eq ${#REQUIRED_SCRIPTS[@]} && $files_present -eq ${#REQUIRED_FILES[@]} ]]; then
    echo -e "${GREEN}✓ Integración completa - proyecto listo${NC}"
    exit_code=0
elif [[ $files_present -eq ${#REQUIRED_FILES[@]} ]]; then
    echo -e "${YELLOW}⚠ Integración parcial - faltan algunos scripts${NC}"
    exit_code=0
else
    echo -e "${RED}✗ Integración incompleta - faltan archivos críticos${NC}"
    exit_code=1
fi

echo ""
echo -e "${BLUE}=== RECOMENDACIONES ===${NC}"

if [[ ${#missing_scripts[@]} -gt 0 ]]; then
    echo "1. Coordinar con otros estudiantes para completar scripts faltantes"
fi

if [[ ! -f "docs/README.md" ]]; then
    echo "2. Crear docs/README.md con documentación básica"
fi

if [[ ! -f "Makefile" ]]; then
    echo "3. Completar Makefile con todos los targets obligatorios"
fi

echo "4. Ejecutar 'make test' cuando todos los componentes estén listos"
echo "5. Probar 'make run' para validar flujo completo"

echo ""
echo -e "${BLUE}=== VALIDACIÓN COMPLETADA ===${NC}"

exit $exit_code