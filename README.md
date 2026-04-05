# Prueba Técnica Banco - CI/CD + Kubernetes en Azure

## Descripción

Pipeline CI/CD completo con **Azure DevOps** para una aplicación **Flask (Python)** desplegada en **AKS (Azure Kubernetes Service)**. Incluye análisis de calidad con **SonarQube**, imágenes Docker en **Docker Hub**, infraestructura como código con **Terraform** y templates con **Helm**.

**Endpoints en producción:**
- App: `http://<AKS-EXTERNAL-IP>/`
- Health: `http://<AKS-EXTERNAL-IP>/health`

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure DevOps                             │
│  ┌────────────────────────┐    ┌─────────────────────────────┐  │
│  │     Stage: CI           │    │     Stage: CD                │  │
│  │                        │    │                             │  │
│  │  1. SonarQube (2 esc.) │───▶│  5. Azure Login (SP)        │  │
│  │  2. Docker Build & Push │    │  6. AKS Get Credentials     │  │
│  │  3. Hola Mundo x10     │    │  7. NGINX Ingress Controller│  │
│  │  4. Crear 10 archivos  │    │  8. kubectl apply manifests │  │
│  └────────────────────────┘    │  9. Verificar endpoint      │  │
│           ubuntu-latest (Cloud)│  └──────────────┬──────────────┘  │
└────────────────────────────────────────────────┼─────────────────┘
                                                 │
                    ┌────────────────────────────▼────────────┐
                    │         Azure Kubernetes Service         │
                    │  ┌─────────────────────────────────────┐ │
                    │  │  namespace: flask-app                │ │
                    │  │  ┌──────────┐  ┌──────────────────┐ │ │
                    │  │  │ Pod (x2) │  │ Service (CIP)    │ │ │
                    │  │  │ Flask    │◀─│ :80 → :8000      │ │ │
                    │  │  │ Gunicorn │  └──────────────────┘ │ │
                    │  │  └──────────┘                       │ │
                    │  │  ┌───────────────────────────────┐ │ │
                    │  │  │ Ingress (NGINX Controller)    │ │ │
                    │  │  │ LoadBalancer → External IP    │ │ │
                    │  │  └───────────────────────────────┘ │ │
                    │  └─────────────────────────────────────┘ │
                    │  Location: southcentralus                │
                    │  Node: Standard_B2pls_v2 (1 nodo)       │
                    └─────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
pruebatecnica-banco/
├── app/                              # Código fuente Flask
│   ├── app.py                        # Aplicación principal (2 endpoints)
│   ├── requirements.txt              # Dependencias Python
│   └── tests/
│       ├── __init__.py
│       └── test_app.py               # Tests unitarios (96% cobertura)
│
├── environment/                      # Manifiestos K8s (YAML plano)
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── service.yaml                  # ClusterIP (tráfico vía Ingress)
│   └── ingress.yaml                  # NGINX Ingress (endpoint externo)
│
├── helm/flask-app/                   # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── _helpers.tpl
│       ├── NOTES.txt
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
│
├── terraform/                        # IaC para AKS
│   ├── main.tf                       # Providers (azurerm, helm, kubernetes)
│   ├── aks.tf                        # Resource Group + AKS Cluster
│   ├── kubernetes.tf                 # Namespace, Secret, NGINX Ingress, Helm
│   ├── variables.tf                  # Variables con defaults
│   ├── outputs.tf                    # Outputs del clúster
│   └── terraform.tfvars              # Valores de la prueba
│
├── pipelines/templates/              # Templates del pipeline
│   ├── variables.yml                 # Variables compartidas
│   ├── ci.yml                        # Stage CI (5 jobs, Bash)
│   └── cd.yml                        # Stage CD (deploy AKS, Bash)
│
├── azure-pipelines.yml               # Pipeline orquestador (ubuntu-latest)
├── Dockerfile                        # Multi-stage build (Python 3.12)
├── sonar-project.properties          # Config SonarQube/SonarCloud
├── .gitignore
└── .dockerignore
```

---

## Requisitos

| Herramienta | Versión  | Uso                              |
|-------------|----------|----------------------------------|
| Docker      | 24+      | Build de imágenes (buildx multi-arch) |
| Python      | 3.12+    | Framework Flask                  |
| SonarQube   | 9+ / SonarCloud | Análisis de calidad       |
| Azure CLI   | 2.60+    | Gestión de Azure                 |
| kubectl     | 1.28+    | Gestión de Kubernetes            |
| Terraform   | 1.5+     | Infraestructura como código      |
| Helm        | 3+       | Template manager K8s             |

---

## Quick Start

### 1. Ejecutar localmente

```bash
pip install -r app/requirements.txt
cd app && python app.py
# http://localhost:8000
```

### 2. Docker

```bash
docker build -t flask-app .
docker run -d -p 8000:8000 flask-app
```

### 3. Tests y cobertura

```bash
cd app && python -m pytest tests/ -v --cov=. --cov-report=term-missing
```

---

## Despliegue con Terraform (Recomendado)

Terraform crea **toda la infraestructura desde cero**: Resource Group, AKS, Namespace, Docker Secret y despliega la app via Helm.

```bash
cd terraform

# Login en Azure
az login

# Inicializar
terraform init

# Revisar plan
terraform plan

# Crear toda la infraestructura + deploy
terraform apply
# Se pedirá: docker_password (sensible, no se guarda en tfvars)

# Obtener credenciales del clúster
eval $(terraform output -raw aks_get_credentials_command)

# Verificar
kubectl get all -n flask-app
kubectl get ingress -n flask-app  # Ver Ingress
kubectl get svc ingress-nginx-controller -n ingress-nginx  # External IP
```

### Destruir toda la infraestructura

```bash
terraform destroy
```

---

## Pipeline CI/CD (Azure DevOps)

### Estructura: 2 Stages

```
┌─ CI ─────────────────────────────────────────────────────┐
│  Job 1: SonarQube Escenario Fallido (simulación)         │
│  Job 2: SonarQube Escenario Exitoso (análisis real)      │
│  Job 3: Docker Build & Push → Docker Hub         [dep:2] │
│  Job 4: Hola Mundo x10 (Bash)                   [dep:3] │
│  Job 5: Crear 10 archivos con fecha (Bash)       [dep:3] │
│                                    (4 y 5 en paralelo)   │
└──────────────────────────────────────────────────────────┘
                           │
┌─ CD ─────────────────────▼───────────────────────────────┐
│  1. Azure Login con Service Principal                    │
│  2. Obtener credenciales AKS                             │
│  3. Crear namespace + Docker Hub secret                  │
│  4. Instalar NGINX Ingress Controller (Helm)             │
│  5. kubectl apply (todos los manifiestos)                │
│  6. Verificar rollout + endpoint externo (Ingress)       │
│  7. Azure Logout                                         │
└──────────────────────────────────────────────────────────┘
```

### Variables requeridas en Azure DevOps (Pipelines > Edit > Variables)

| Variable              | Tipo    | Descripción                     |
|-----------------------|---------|---------------------------------|
| `DOCKER_PASS`         | Secret  | Contraseña Docker Hub           |
| `SONAR_TOKEN`         | Secret  | Token de SonarQube/SonarCloud   |
| `AZURE_SP_APP_ID`     | Secret  | App ID del Service Principal    |
| `AZURE_SP_SECRET`     | Secret  | Password del Service Principal  |
| `AZURE_TENANT_ID`     | Normal  | Tenant ID de Azure AD           |
| `AZURE_SUBSCRIPTION_ID`| Normal | ID de la suscripción Azure     |

---

## SonarQube

### Escenarios de análisis

| Escenario | Descripción | Quality Gate |
|-----------|-------------|--------------|
| 1 - Fallido | Tests sin reporte de cobertura (simulación) | FAILED |
| 2 - Exitoso | Tests con cobertura + análisis SonarQube real | PASSED |

### Levantar SonarQube (opciones)

**Opción 1: SonarCloud (recomendado para cloud)**
- Crear cuenta en https://sonarcloud.io
- Configurar `SONAR_HOST_URL` como `https://sonarcloud.io`
- Crear token y configurar `SONAR_TOKEN` en pipeline

**Opción 2: SonarQube local (desarrollo)**
```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:community
# Acceder: http://localhost:9000 (admin/admin)
```

---

## Kubernetes

### Manifiestos (carpeta `environment/`)

| Archivo | Recurso | Descripción |
|---------|---------|-------------|
| `namespace.yaml` | Namespace | `flask-app` |
| `configmap.yaml` | ConfigMap | Variables de entorno |
| `deployment.yaml` | Deployment | 2 réplicas, health probes |
| `service.yaml` | Service | ClusterIP (tráfico via Ingress) |
| `ingress.yaml` | Ingress | NGINX Ingress (endpoint externo) |

### Deploy manual con kubectl

```bash
kubectl apply -f environment/
kubectl get ingress -n flask-app  # Ver Ingress
```

### Deploy con Helm

```bash
helm install flask-app helm/flask-app/ -n flask-app --create-namespace
helm upgrade flask-app helm/flask-app/ --set image.tag=<nuevo-tag> -n flask-app
```

---

## Bonus implementados

- [x] Clúster AKS creado con **Terraform** (IaC completa: RG + AKS + NGINX Ingress + Helm)
- [x] **Helm Chart** como manejador de templates con `_helpers.tpl` y `NOTES.txt`
- [x] Despliegue en **nube pública Azure** (AKS en southcentralus)
- [x] Endpoint **accesible desde internet** (NGINX Ingress Controller con IP pública)
- [x] Pipeline con **templates reutilizables** (2 stages: CI + CD)
- [x] **Multi-stage Docker build** (imagen optimizada ~150MB, multi-arch amd64+arm64)
- [x] **Service Principal** para autenticación segura en pipeline
- [x] Variables **sensibles como secrets** en Azure DevOps
- [x] **Terraform providers** para azurerm + kubernetes + helm
- [x] Pipeline **100% en nube** (agentes `ubuntu-latest`, sin agente local)
- [x] **Docker buildx** multi-arquitectura desde el pipeline

---

## Limpieza de recursos

```bash
# Opción 1: Terraform (si se creó con Terraform)
cd terraform && terraform destroy

# Opción 2: Azure CLI
az group delete --name rg-pruebatecnica --yes --no-wait
```
