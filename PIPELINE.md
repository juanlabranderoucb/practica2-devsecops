# Pipeline DevSecOps CI/CD

## 📋 Descripción General

Pipeline completo de DevSecOps que implementa todas las etapas de seguridad y calidad desde el desarrollo hasta el despliegue.

## 🔄 Flujo del Pipeline

```
Push/PR → Instalación → Calidad → Tests → SAST → SCA → Build → Scan → Deploy → Smoke Tests
```

## 📊 Etapas del Pipeline

### 1. ✅ Instalación Reproducible
**Objetivo**: Garantizar instalaciones consistentes y reproducibles

- **Herramienta**: `npm ci`
- **Características**:
  - Instalación desde package-lock.json
  - Falla si hay inconsistencias
  - Cache de dependencias para velocidad
  - `--prefer-offline` para usar cache
  - `--no-audit` para evitar auditorías duplicadas

**Criterio de fallo**: Pipeline detiene si falla la instalación

### 2. 🔍 Análisis de Calidad de Código (ESLint)
**Objetivo**: Detectar errores de sintaxis y malas prácticas

- **Herramienta**: ESLint
- **Configuración**: `.eslintrc.js` en cada servicio
- **Reglas activadas**:
  - Variables no usadas (error)
  - Uso de eval (error)
  - Funciones implícitas (error)
  - Recomendaciones ES2021

**Criterio de fallo**: `--max-warnings=0` (cero warnings permitidos)

### 3. 🧪 Testing Automatizado
**Objetivo**: Verificar funcionalidad y prevenir regresiones

- **Framework**: Jest
- **Cobertura**: Activada con `--coverage`
- **Servicios testeados**:
  - users-service
  - academic-service
  - api-gateway
  - frontend

**Criterio de fallo**: Pipeline detiene si algún test falla

### 4. 🔒 SAST - Análisis Estático de Seguridad

#### 4.1 Semgrep (Análisis Rápido)
- **Ejecución**: Análisis rápido de patrones conocidos
- **Configuración**: `--config=auto --severity=ERROR`
- **Detecta**:
  - Secretos hardcodeados
  - Uso de eval()
  - Inyección SQL
  - XSS potenciales

#### 4.2 SonarQube (Análisis Profundo)
- **Herramienta**: SonarQube Cloud
- **Configuración**:
  - Secrets: `SONAR_HOST_URL`, `SONAR_TOKEN`
  - Archivo: `sonar-project.properties`
- **Analiza**:
  - Bugs y code smells
  - Vulnerabilidades de seguridad
  - Deuda técnica
  - Cobertura de código
  - Duplicaciones

**Quality Gate**: Pipeline falla si no cumple con los umbrales de SonarQube

### 5. 🛡️ SCA - Análisis de Dependencias
**Objetivo**: Detectar vulnerabilidades en librerías de terceros

- **Herramienta**: `npm audit`
- **Configuración**: `--audit-level=high --production`
- **Detecta**:
  - CVEs conocidos en dependencias
  - Vulnerabilidades HIGH y CRITICAL
  - Solo dependencias de producción

**Criterio de fallo**: Pipeline detiene ante vulnerabilidades HIGH o CRITICAL

### 6. 🐋 Build de Contenedores
**Objetivo**: Crear imágenes Docker optimizadas y versionadas

- **Características**:
  - Multi-stage builds (frontend)
  - Versionado con SHA del commit
  - Labels con metadata Git
  - Buildx para optimización

**Tags generados**:
- `latest` - Última versión estable
- `<commit-sha>` - Versión específica del commit

**Labels**:
```yaml
git.commit: <sha>
git.branch: <branch-name>
```

### 7. 🔐 Seguridad de Contenedores (Trivy)
**Objetivo**: Escanear imágenes por vulnerabilidades

- **Herramienta**: Trivy (Aqua Security)
- **Configuración**:
  - Severidad: `CRITICAL,HIGH`
  - Exit code: 1 (falla el pipeline)
  - Ignore unfixed: true

**Escanea**:
- ✅ Vulnerabilidades del sistema base (Alpine)
- ✅ Dependencias del sistema
- ✅ Librerías instaladas
- ✅ CVEs conocidos

**Criterio de fallo**: Cualquier vulnerabilidad CRITICAL o HIGH

### 8. 🚀 Smoke Tests
**Objetivo**: Verificar que los servicios funcionan correctamente

- **Método**: Health checks HTTP
- **Servicios verificados**:
  - users-service (puerto 3001)
  - academic-service (puerto 3002)
  - api-gateway (puerto 3000)
  - frontend (puerto 5173)

**Criterio de fallo**: Si algún servicio no responde

## 🎯 Criterios de Éxito del Pipeline

El pipeline solo pasa si **TODAS** estas condiciones se cumplen:

1. ✅ Instalación de dependencias exitosa
2. ✅ ESLint sin errores ni warnings
3. ✅ Todos los tests pasan
4. ✅ Semgrep no encuentra vulnerabilidades ERROR
5. ✅ SonarQube Quality Gate aprobado
6. ✅ npm audit sin vulnerabilidades HIGH/CRITICAL
7. ✅ Build de Docker exitoso
8. ✅ Trivy no encuentra vulnerabilidades CRITICAL/HIGH
9. ✅ Todos los smoke tests pasan

## 🔧 Requisitos Previos

### Secrets de GitHub

Configurar en Settings → Secrets and variables → Actions:

```yaml
SONAR_TOKEN: <token-de-sonarqube>
SONAR_HOST_URL: https://sonarcloud.io
```

### Archivos Necesarios

- `.github/workflows/devsecops.yml` - Pipeline principal
- `sonar-project.properties` - Configuración SonarQube
- `.eslintrc.js` - Configuración ESLint (cada servicio)
- `.env.example` - Templates de variables de entorno

## 📈 Métricas y Reportes

### SonarQube
- URL: Configurada en `SONAR_HOST_URL`
- Dashboard: Calidad de código, cobertura, vulnerabilidades

### Trivy
- Formato: Table (en consola)
- Reporte completo en logs del pipeline

### npm audit
- Reporte completo de vulnerabilidades
- Solo dependencias de producción

## 🚦 Triggers del Pipeline

```yaml
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
```

- **Push a main**: Ejecuta pipeline completo
- **Pull Request**: Ejecuta pipeline completo antes de merge

## 🛠️ Comandos Locales

### Ejecutar las etapas localmente:

```bash
# 1. Instalación
cd backend/users-service && npm ci

# 2. Calidad de código
npm run lint

# 3. Tests
npm test -- --coverage

# 4. SAST (Semgrep)
semgrep --config=auto --severity=ERROR

# 5. SCA
npm audit --audit-level=high --production

# 6. Build Docker
docker build -t users-service:local .

# 7. Scan Docker
trivy image users-service:local --severity CRITICAL,HIGH
```

## 📝 Mantenimiento

### Actualizar dependencias seguras:

```bash
# Ver actualizaciones disponibles
npm outdated

# Actualizar dependencias menores
npm update

# Auditar después de actualizar
npm audit fix
```

### Actualizar configuración de seguridad:

1. Revisar nuevas reglas de Semgrep
2. Actualizar Quality Gates en SonarQube
3. Revisar políticas de Trivy

## 🎓 Buenas Prácticas Implementadas

✅ **Shift-Left Security**: Seguridad desde el inicio  
✅ **Instalación Reproducible**: `npm ci` en lugar de `npm install`  
✅ **Fail Fast**: Pipeline falla rápido ante problemas  
✅ **Análisis Multicapa**: SAST + SCA + Container Scanning  
✅ **Versionado Semántico**: Tags con commit SHA  
✅ **Smoke Tests**: Validación post-deploy  
✅ **Pipeline as Code**: Todo versionado en Git  

## 🔍 Troubleshooting

### Pipeline falla en npm audit
```bash
# Ver detalles
npm audit

# Arreglar automáticamente
npm audit fix

# Forzar arreglos (puede romper)
npm audit fix --force
```

### Pipeline falla en ESLint
```bash
# Ver errores
npm run lint

# Auto-arreglar
npx eslint src/ --fix
```

### Pipeline falla en SonarQube
1. Revisar dashboard de SonarQube
2. Verificar Quality Gate configurado
3. Corregir issues críticos reportados

### Pipeline falla en Trivy
```bash
# Ver detalles localmente
trivy image <imagen>:latest

# Actualizar imagen base en Dockerfile
# Actualizar dependencias vulnerables
```

## 📚 Referencias

- [GitHub Actions](https://docs.github.com/en/actions)
- [SonarQube](https://docs.sonarqube.org/)
- [Trivy](https://aquasecurity.github.io/trivy/)
- [Semgrep](https://semgrep.dev/docs/)
- [ESLint](https://eslint.org/docs/)
- [npm audit](https://docs.npmjs.com/cli/v8/commands/npm-audit)
