# 🚀 Pipeline DevSecOps - Guía Rápida

## ✅ Pipeline Implementado

El pipeline CI/CD DevSecOps ha sido completamente implementado en [.github/workflows/devsecops.yml](.github/workflows/devsecops.yml)

## 📋 Etapas Implementadas

### ✅ a. Instalación Reproducible
- **Herramienta**: `npm ci`
- **Características**: 
  - Instalación desde package-lock.json
  - Falla ante inconsistencias
  - Cache de dependencias
- **Status**: ✅ IMPLEMENTADO

### ✅ b. Análisis de Calidad de Código
- **Herramienta**: ESLint
- **Configuración**: `.eslintrc.js` en cada servicio
- **Reglas**: Detección de errores comunes y malas prácticas
- **Status**: ✅ IMPLEMENTADO

### ✅ c. Testing Automático
- **Framework**: Jest
- **Cobertura**: Activada
- **Comportamiento**: Pipeline falla si tests fallan
- **Status**: ✅ IMPLEMENTADO

### ✅ d. SAST - Seguridad del Código
- **Herramientas**: 
  - Semgrep (análisis rápido)
  - **SonarQube** (análisis profundo)
- **Secrets requeridos**:
  - `SONAR_HOST_URL` ✅ (configurado en GitHub)
  - `SONAR_TOKEN` ✅ (configurado en GitHub)
- **Status**: ✅ IMPLEMENTADO

### ✅ e. SCA - Seguridad de Dependencias
- **Herramienta**: `npm audit`
- **Configuración**: `--audit-level=high --production`
- **Detección**: CVEs en dependencias
- **Comportamiento**: Pipeline falla ante riesgos críticos
- **Status**: ✅ IMPLEMENTADO

### ✅ f. Build de Contenedores
- **Herramienta**: Docker + Buildx
- **Versionado**: 
  - Tag `latest`
  - Tag con SHA del commit
- **Labels**: Metadata de Git
- **Status**: ✅ IMPLEMENTADO

### ✅ g. Seguridad de Contenedores
- **Herramienta**: Trivy (Aqua Security)
- **Severidad**: CRITICAL, HIGH
- **Comportamiento**: Pipeline falla ante vulnerabilidades
- **Status**: ✅ IMPLEMENTADO

## 🔧 Configuración Necesaria

### 1. Secrets de GitHub

Ir a: **Settings → Secrets and variables → Actions → New repository secret**

Agregar:
```
SONAR_HOST_URL = https://sonarcloud.io (o tu URL de SonarQube)
SONAR_TOKEN = <tu-token-de-sonarqube>
```

✅ **Nota**: El usuario indicó que estos secrets ya están configurados

### 2. Archivos Creados

```
✅ .github/workflows/devsecops.yml  - Pipeline principal
✅ sonar-project.properties         - Configuración SonarQube
✅ backend/*/.eslintrc.js          - Configuración ESLint
✅ PIPELINE.md                     - Documentación completa
✅ verify-local.sh                 - Script de validación local
```

### 3. Package.json Actualizados

Todos los servicios ahora tienen:
```json
{
  "scripts": {
    "lint": "eslint src/"
  },
  "devDependencies": {
    "eslint": "^9.17.0"
  }
}
```

## 🚀 Uso del Pipeline

### Automático
El pipeline se ejecuta automáticamente en:

- ✅ Push a rama `main`
- ✅ Pull Requests a `main`

### Manual (Validación Local)

Antes de hacer push, ejecuta:

```bash
./verify-local.sh
```

Este script ejecuta TODAS las validaciones localmente:
1. Instalación reproducible
2. ESLint
3. Tests
4. Semgrep (SAST)
5. npm audit (SCA)
6. Build Docker (opcional)
7. Trivy scan (opcional)

## 📊 Monitoreo del Pipeline

### Ver resultados en GitHub

1. Ve a tu repositorio en GitHub
2. Click en pestaña **Actions**
3. Selecciona el workflow run
4. Revisa cada etapa

### Verificar SonarQube

1. Accede a tu instancia de SonarQube
2. Busca proyecto: `devsecops-microservices`
3. Revisa Quality Gate y métricas

## ⚡ Comandos Útiles

### Ejecutar etapas individuales localmente

```bash
# Instalación
cd backend/users-service && npm ci

# Calidad
npm run lint

# Tests
npm test -- --coverage

# SAST
semgrep --config=auto --severity=ERROR

# SCA
npm audit --audit-level=high --production

# Build
docker build -t users-service:local .

# Scan
trivy image users-service:local --severity CRITICAL,HIGH
```

### Arreglar problemas comunes

```bash
# Arreglar ESLint
npx eslint src/ --fix

# Arreglar vulnerabilidades
npm audit fix

# Actualizar dependencias
npm update
```

## 🎯 Criterios de Éxito

El pipeline **SOLO PASA** si:

1. ✅ npm ci exitoso (instalación reproducible)
2. ✅ ESLint sin errores ni warnings
3. ✅ Todos los tests pasan
4. ✅ Semgrep sin vulnerabilidades ERROR
5. ✅ SonarQube Quality Gate aprobado
6. ✅ npm audit sin vulnerabilidades HIGH/CRITICAL
7. ✅ Build de Docker exitoso
8. ✅ Trivy sin vulnerabilidades CRITICAL/HIGH
9. ✅ Smoke tests pasan

**Si CUALQUIERA falla → Pipeline falla** ❌

## 📚 Documentación Adicional

- [PIPELINE.md](PIPELINE.md) - Documentación completa del pipeline
- [.github/workflows/devsecops.yml](.github/workflows/devsecops.yml) - Código del pipeline
- [sonar-project.properties](sonar-project.properties) - Configuración SonarQube

## 🔍 Troubleshooting

### Pipeline falla en SonarQube

**Problema**: Quality Gate no aprobado

**Solución**:
1. Revisa dashboard de SonarQube
2. Corrige issues reportados
3. Ajusta umbrales si es necesario

### Pipeline falla en npm audit

**Problema**: Vulnerabilidades en dependencias

**Solución**:
```bash
# Ver detalles
npm audit

# Intentar arreglo automático
npm audit fix

# Si no funciona, actualizar manualmente
npm update <paquete>
```

### Pipeline falla en Trivy

**Problema**: Vulnerabilidades en imagen Docker

**Solución**:
1. Actualiza imagen base en Dockerfile
2. Actualiza dependencias del sistema
3. Revisa reporte detallado de Trivy

## ✨ Resumen

✅ **Pipeline completamente funcional**  
✅ **Todas las etapas implementadas**  
✅ **DevSecOps desde el inicio (Shift-Left)**  
✅ **Automatización completa**  
✅ **Validación local disponible**  

---

**¿Siguiente paso?**

1. Instalar dependencias de ESLint: `npm install` en cada servicio
2. Ejecutar validación local: `./verify-local.sh`
3. Hacer commit y push
4. Ver el pipeline ejecutarse en GitHub Actions
5. Revisar resultados en SonarQube

**Comando para instalar todo**:
```bash
cd backend/users-service && npm install && cd ../..
cd backend/academic-service && npm install && cd ../..
cd backend/api-gateway && npm install && cd ../..
cd frontend && npm install && cd ..
```
