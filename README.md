# Prueba Técnica - Flask App CI/CD + Kubernetes

## Descripción

Aplicación web **Flask (Python)** tomada del catálogo de [Docker Samples - Frameworks](https://docs.docker.com/samples/), con un pipeline CI/CD completo en **Azure DevOps** que incluye análisis de calidad con SonarQube, construcción de imagen Docker, y despliegue a un clúster de **Kubernetes**.

## Estructura del Proyecto

```
pruebatecnica/
├── app/                          # Código fuente de la aplicación
│   ├── app.py                    # Aplicación Flask principal
│   ├── requirements.txt          # Dependencias Python
│   └── tests/                    # Tests unitarios
│       ├── __init__.py
│       └── test_app.py
├── environment/                  # Manifiestos de Kubernetes (YAML)
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── configmap.yaml
├── helm/                         # Helm Chart (bonus)
│   └── flask-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── namespace.yaml
│           ├── deployment.yaml
│           ├── service.yaml
│           └── ingress.yaml
├── terraform/                    # IaC con Terraform para AKS (bonus)
│   ├── main.tf
│   ├── variables.tf
│   ├── aks.tf
│   └── outputs.tf
├── azure-pipelines.yml           # Pipeline CI/CD de Azure DevOps
├── Dockerfile                    # Multi-stage Docker build
├── .dockerignore
├── .gitignore
├── sonar-project.properties      # Configuración de SonarQube
└── README.md                     # Esta documentación
```

---

## Prerrequisitos

| Herramienta       | Versión Mínima | Propósito                         |
| ----------------- | -------------- | --------------------------------- |
| Docker            | 24+            | Build de imágenes                 |
| Python            | 3.12+          | Framework Flask                   |
| SonarQube         | 9+             | Análisis de calidad               |
| Azure DevOps      | -              | CI/CD Pipeline                    |
| kubectl           | 1.28+          | Gestión de Kubernetes             |
| Minikube / AKS    | -              | Clúster de Kubernetes             |
| Helm (opcional)   | 3+             | Template manager                  |
| Terraform (bonus) | 1.5+           | Infraestructura como código (AKS) |

---

## 1. Configuración Local

### 1.1 Clonar el repositorio

```bash
git clone https://github.com/<tu-usuario>/pruebatecnica.git
cd pruebatecnica
```

### 1.2 Instalar dependencias Python

```bash
pip install -r app/requirements.txt
```

### 1.3 Ejecutar la aplicación localmente

```bash
cd app
python app.py
# Abrir http://localhost:8000
```

### 1.4 Ejecutar tests

```bash
cd app
python -m pytest tests/ -v --cov=. --cov-report=term-missing
```

---

## 2. Docker

### 2.1 Build de la imagen

```bash
docker build -t flask-app:latest .
```

### 2.2 Ejecutar el contenedor

```bash
docker run -d -p 8000:8000 --name flask-app flask-app:latest
# Probar: curl http://localhost:8000
# Health: curl http://localhost:8000/health
```

### 2.3 Push a Docker Hub / ACR

```bash
# Docker Hub
docker tag flask-app:latest <tu-usuario>/flask-app:latest
docker push <tu-usuario>/flask-app:latest

# Azure Container Registry
az acr login --name <tu-acr>
docker tag flask-app:latest <tu-acr>.azurecr.io/flask-app:latest
docker push <tu-acr>.azurecr.io/flask-app:latest
```

---

## 3. SonarQube

### 3.1 Levantar SonarQube con Docker

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
```

Acceder a `http://localhost:9000` (usuario: `admin`, password: `admin`).

### 3.2 Configurar proyecto

1. Crear proyecto con key: `pruebatecnica`
2. Generar token de autenticación
3. Configurar Quality Gate personalizado:
   - **Cobertura mínima**: 80%
   - **Duplicación máxima**: 3%
   - **Bugs**: 0
   - **Vulnerabilidades**: 0

### 3.3 Escenarios de análisis

| Escenario   | Descripción                              | Resultado     |
| ----------- | ---------------------------------------- | ------------- |
| Escenario 1 | Tests sin cobertura suficiente           | **FAILED** ❌ |
| Escenario 2 | Tests con cobertura completa (>80%)      | **PASSED** ✅ |

El pipeline ejecuta ambos escenarios en paralelo para demostrar los dos casos.

### 3.4 Ejecutar análisis local

```bash
sonar-scanner \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<tu-token>
```

---

## 4. Azure DevOps Pipeline

### 4.1 Prerrequisitos en Azure DevOps

1. **Organización y Proyecto** de Azure DevOps creados
2. **Agent Pool Self-Hosted** configurado con nombre `SelfHosted`
3. **Service Connections** creadas:
   - `docker-registry` → Docker Hub o ACR
   - `sonarqube-service` → SonarQube server
   - `k8s-connection` → Kubernetes cluster
4. **Variable Group** `prueba-tecnica-vars` con:
   - `DOCKER_REGISTRY`: URL del registry (ej: `docker.io/tuusuario`)
   - `IMAGE_NAME`: nombre de la imagen (ej: `flask-app`)
   - `SONAR_HOST_URL`: URL de SonarQube (ej: `http://sonarqube:9000`)
   - `SONAR_TOKEN`: token de SonarQube

### 4.2 Estructura del Pipeline

El pipeline (`azure-pipelines.yml`) tiene **4 stages**:

```
Stage 1: QualityAnalysis
├── Job: Escenario 1 - Análisis Fallido (simulación)
└── Job: Escenario 2 - Análisis Exitoso (SonarQube real)

Stage 2: BuildAndPush
└── Job: Docker Build & Push a Registry

Stage 3: ScriptExecution (Jobs en paralelo)
├── Job 3a: "Hola Mundo" x10 (Bash)
└── Job 3b: Crear 10 archivos con fecha (PowerShell)

Stage 4: DeployToK8s
└── Job: Deploy manifiestos a Kubernetes
```

### 4.3 Configurar el pipeline

1. Ir a **Pipelines** → **New Pipeline**
2. Seleccionar repositorio
3. Elegir **Existing Azure Pipelines YAML file**
4. Seleccionar `azure-pipelines.yml`
5. Ejecutar

---

## 5. Kubernetes

### 5.1 Opción A: Minikube (local)

```bash
# Iniciar minikube
minikube start --driver=hyperv   # o docker/virtualbox

# Habilitar ingress
minikube addons enable ingress

# Aplicar manifiestos
kubectl apply -f environment/namespace.yaml
kubectl apply -f environment/configmap.yaml
kubectl apply -f environment/deployment.yaml
kubectl apply -f environment/service.yaml
kubectl apply -f environment/ingress.yaml

# Verificar
kubectl get all -n flask-app
kubectl get ingress -n flask-app

# Acceder (agregar a /etc/hosts o C:\Windows\System32\drivers\etc\hosts):
# <minikube-ip>  flask-app.local
minikube ip
```

### 5.2 Opción B: AKS con Terraform (bonus)

```bash
cd terraform

# Inicializar
terraform init

# Planificar
terraform plan -out=tfplan

# Aplicar
terraform apply tfplan

# Obtener credenciales
az aks get-credentials \
  --resource-group rg-pruebatecnica \
  --name aks-pruebatecnica

# Instalar NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Desplegar la app
kubectl apply -f environment/
```

### 5.3 Deploy con Helm (bonus)

```bash
# Instalar el chart
helm install flask-app helm/flask-app/ \
  --set image.repository=<tu-registry>/flask-app \
  --set image.tag=latest \
  --namespace flask-app \
  --create-namespace

# Actualizar
helm upgrade flask-app helm/flask-app/ \
  --set image.tag=<nuevo-tag>

# Verificar
helm list -n flask-app
kubectl get all -n flask-app
```

### 5.4 Verificar el despliegue

```bash
# Pods
kubectl get pods -n flask-app

# Servicios
kubectl get svc -n flask-app

# Ingress (endpoint externo)
kubectl get ingress -n flask-app

# Logs
kubectl logs -l app=flask-app -n flask-app

# Test endpoint
curl http://flask-app.local/
curl http://flask-app.local/health
```

---

## 6. Acceso desde Internet (Bonus)

### Con AKS + Ingress Controller

1. El Ingress Controller crea un **LoadBalancer** con IP pública
2. Obtener la IP:
   ```bash
   kubectl get svc -n ingress-nginx
   ```
3. Configurar DNS apuntando al IP público, o usar `nip.io`:
   ```bash
   # Si la IP es 20.120.50.100:
   curl http://flask-app.20.120.50.100.nip.io/
   ```
4. Para HTTPS, configurar cert-manager + Let's Encrypt (descomentando la sección TLS del ingress)

---

## 7. Configuración Self-Hosted Agent

### 7.1 Instalar agente en la máquina

```bash
# Descargar agente desde Azure DevOps → Organization Settings → Agent Pools
mkdir azagent && cd azagent
# Descomprimir el agente descargado

# Configurar
./config.sh --url https://dev.azure.com/<tu-org> \
  --auth pat \
  --token <tu-pat> \
  --pool SelfHosted \
  --agent my-agent

# Ejecutar
./run.sh
```

### 7.2 Herramientas requeridas en el agente

- Docker
- Python 3.12
- sonar-scanner CLI
- kubectl
- helm (opcional)

---

## 8. Resumen de Entregables

| Entregable                    | Ubicación                     |
| ----------------------------- | ----------------------------- |
| Código de la aplicación       | `app/`                        |
| YAML de Kubernetes            | `environment/`                |
| Pipeline CI/CD                | `azure-pipelines.yml`         |
| Dockerfile                    | `Dockerfile`                  |
| SonarQube config              | `sonar-project.properties`    |
| Helm Chart (bonus)            | `helm/flask-app/`             |
| Terraform IaC (bonus)         | `terraform/`                  |
| Documentación                 | `README.md`                   |
| Logs                          | Azure DevOps Pipeline Runs    |
| Printscreen                   | Capturas de cada ejecutación  |
