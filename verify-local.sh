#!/bin/bash

# ========================================
# Script de Validación Local DevSecOps
# ========================================
# Ejecuta todas las validaciones del pipeline localmente
# antes de hacer push a GitHub

set -e  # Detener en caso de error

echo "🚀 Iniciando validación DevSecOps local..."
echo "=========================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Servicios a validar
SERVICES=("users-service" "academic-service" "api-gateway")

# ========================================
# 1. Instalación Reproducible
# ========================================
echo ""
echo "📦 1. Instalación reproducible de dependencias..."
echo "=========================================="

for service in "${SERVICES[@]}"; do
    echo "   → $service"
    cd "backend/$service"
    npm ci --prefer-offline --no-audit > /dev/null 2>&1
    cd ../..
done

cd frontend
echo "   → frontend"
npm ci --prefer-offline --no-audit > /dev/null 2>&1
cd ..

echo -e "${GREEN}✅ Dependencias instaladas correctamente${NC}"

# ========================================
# 2. Análisis de Calidad (ESLint)
# ========================================
echo ""
echo "🔍 2. Análisis de calidad de código (ESLint)..."
echo "=========================================="

ESLINT_ERRORS=0

for service in "${SERVICES[@]}"; do
    echo "   → $service"
    cd "backend/$service"
    if ! npx eslint src/ --max-warnings=0 2>&1 | grep -v "warning"; then
        ESLINT_ERRORS=$((ESLINT_ERRORS + 1))
    fi
    cd ../..
done

echo "   → frontend"
cd frontend
if ! npm run lint 2>&1 | grep -q "error"; then
    echo -e "${GREEN}✅ ESLint: Sin errores${NC}"
else
    ESLINT_ERRORS=$((ESLINT_ERRORS + 1))
fi
cd ..

if [ $ESLINT_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ ESLint encontró errores. Corrígelos antes de continuar.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Calidad de código verificada${NC}"

# ========================================
# 3. Tests Automatizados
# ========================================
echo ""
echo "🧪 3. Tests automatizados..."
echo "=========================================="

for service in "${SERVICES[@]}"; do
    echo "   → $service"
    cd "backend/$service"
    npm test -- --passWithNoTests --silent > /dev/null 2>&1
    cd ../..
done

echo "   → frontend"
cd frontend
npm test -- --passWithNoTests --silent > /dev/null 2>&1
cd ..

echo -e "${GREEN}✅ Todos los tests pasaron${NC}"

# ========================================
# 4. SAST - Semgrep
# ========================================
echo ""
echo "🔒 4. SAST - Análisis estático de seguridad (Semgrep)..."
echo "=========================================="

# Verificar si semgrep está instalado
if ! command -v semgrep &> /dev/null; then
    echo -e "${YELLOW}⚠️  Semgrep no instalado. Instalando...${NC}"
    pip install semgrep > /dev/null 2>&1
fi

SEMGREP_ERRORS=0

for service in "${SERVICES[@]}"; do
    echo "   → $service"
    cd "backend/$service"
    if ! semgrep --config=auto --severity=ERROR --quiet 2>&1; then
        SEMGREP_ERRORS=$((SEMGREP_ERRORS + 1))
    fi
    cd ../..
done

echo "   → frontend"
cd frontend
if ! semgrep --config=auto --severity=ERROR --quiet 2>&1; then
    SEMGREP_ERRORS=$((SEMGREP_ERRORS + 1))
fi
cd ..

if [ $SEMGREP_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ Semgrep encontró vulnerabilidades${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SAST: Sin vulnerabilidades críticas${NC}"

# ========================================
# 5. SCA - Análisis de Dependencias
# ========================================
echo ""
echo "🛡️  5. SCA - Análisis de dependencias..."
echo "=========================================="

SCA_ERRORS=0

for service in "${SERVICES[@]}"; do
    echo "   → $service"
    cd "backend/$service"
    if ! npm audit --audit-level=high --production > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Vulnerabilidades encontradas en $service${NC}"
        npm audit --audit-level=high --production
        SCA_ERRORS=$((SCA_ERRORS + 1))
    fi
    cd ../..
done

echo "   → frontend"
cd frontend
if ! npm audit --audit-level=high --production > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Vulnerabilidades encontradas en frontend${NC}"
    npm audit --audit-level=high --production
    SCA_ERRORS=$((SCA_ERRORS + 1))
fi
cd ..

if [ $SCA_ERRORS -gt 0 ]; then
    echo -e "${RED}❌ npm audit encontró vulnerabilidades HIGH/CRITICAL${NC}"
    echo -e "${YELLOW}💡 Ejecuta 'npm audit fix' en los servicios afectados${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SCA: Sin vulnerabilidades críticas${NC}"

# ========================================
# 6. Build de Contenedores (opcional)
# ========================================
echo ""
read -p "🐋 ¿Quieres construir y escanear las imágenes Docker? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "=========================================="
    
    # Crear .env files
    echo "   Creando archivos .env..."
    cp backend/users-service/.env.example backend/users-service/.env
    cp backend/academic-service/.env.example backend/academic-service/.env
    cp backend/api-gateway/.env.example backend/api-gateway/.env
    cp frontend/.env.example frontend/.env
    
    # Build
    echo "   Construyendo imágenes..."
    cd backend
    docker compose build > /dev/null 2>&1
    cd ..
    
    echo -e "${GREEN}✅ Imágenes construidas${NC}"
    
    # ========================================
    # 7. Scan de Contenedores
    # ========================================
    echo ""
    echo "🔐 7. Escaneando imágenes con Trivy..."
    echo "=========================================="
    
    # Verificar si trivy está instalado
    if ! command -v trivy &> /dev/null; then
        echo -e "${YELLOW}⚠️  Trivy no instalado. Instálalo desde: https://aquasecurity.github.io/trivy/${NC}"
    else
        for service in "${SERVICES[@]}"; do
            echo "   → $service:latest"
            if ! trivy image --severity CRITICAL,HIGH --exit-code 1 "$service:latest" > /dev/null 2>&1; then
                echo -e "${RED}❌ Vulnerabilidades encontradas en $service${NC}"
                trivy image --severity CRITICAL,HIGH "$service:latest"
                exit 1
            fi
        done
        
        echo "   → frontend:latest"
        if ! trivy image --severity CRITICAL,HIGH --exit-code 1 "frontend:latest" > /dev/null 2>&1; then
            echo -e "${RED}❌ Vulnerabilidades encontradas en frontend${NC}"
            trivy image --severity CRITICAL,HIGH "frontend:latest"
            exit 1
        fi
        
        echo -e "${GREEN}✅ Escaneo de contenedores: Sin vulnerabilidades críticas${NC}"
    fi
fi

# ========================================
# RESUMEN FINAL
# ========================================
echo ""
echo "=========================================="
echo -e "${GREEN}🎉 ¡TODAS LAS VALIDACIONES PASARON!${NC}"
echo "=========================================="
echo "✅ Instalación reproducible"
echo "✅ Calidad de código (ESLint)"
echo "✅ Tests automatizados"
echo "✅ SAST (Semgrep)"
echo "✅ SCA (npm audit)"
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "✅ Build de contenedores"
    if command -v trivy &> /dev/null; then
        echo "✅ Escaneo de contenedores (Trivy)"
    fi
fi
echo "=========================================="
echo ""
echo -e "${GREEN}✨ Tu código está listo para push a GitHub${NC}"
echo ""
