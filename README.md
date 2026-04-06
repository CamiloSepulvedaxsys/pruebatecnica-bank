# Prueba Técnica Banco - CI/CD + Kubernetes en Azure

## Descripción

Pipeline CI/CD completo con **Azure DevOps** para una aplicación **Flask (Python)** desplegada en **AKS (Azure Kubernetes Service)**.

| Componente | Tecnología |
|---|---|
| Aplicación | Flask 3.1 + Gunicorn (Python 3.12) |
| Contenedor | Docker multi-stage, multi-arch (amd64 + arm64) |
| Orquestador | Kubernetes en AKS (Azure) |
| Infraestructura | Terraform (azurerm + helm + kubernetes providers) |
| Templates K8s | Helm Chart |
| CI/CD | Azure DevOps Pipelines (self-hosted Windows agent) |
| Calidad | SonarCloud (análisis estático + Quality Gate) |
| Seguridad | CSRFProtect, non-root container, secret management |
| Ingress | NGINX Ingress Controller con IP pública estática |

**Endpoint en producción:** `http://20.114.65.15`

---

## Arquitectura

```
                         Azure DevOps Pipeline
  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  ┌─ CI ──────────────────────┐  ┌─ CD ────────────────────┐ │
  │  │                           │  │                          │ │
  │  │ SonarQube (2 escenarios)  │  │ Login AKS (Service Conn) │ │
  │  │ Tests + Cobertura (95%)   │──▶ kubectl apply manifests  │ │
  │  │ Docker Build & Push       │  │ Rollout + Health Check   │ │
  │  │ Scripts paralelos (x2)    │  │                          │ │
  │  └──────────────────────────-┘  └────────────┬─────────────┘ │
  │    Self-hosted Windows (PowerShell)           │              │
  └───────────────────────────────────────────────┼──────────────┘
                                                  │
              ┌───────────────────────────────────▼──────────────┐
              │           Azure Kubernetes Service               │
              │                                                  │
              │  ┌─ ingress-nginx ─────────────────────────────┐ │
              │  │  NGINX Ingress Controller                   │ │
              │  │  LoadBalancer → IP: 20.114.65.15 (estática) │ │
              │  └─────────────────────────┬───────────────────┘ │
              │                            │                     │
              │  ┌─ flask-app ─────────────▼───────────────────┐ │
              │  │  Ingress → Service (ClusterIP :80)          │ │
              │  │     ├── Pod 1 (Flask + Gunicorn :8000)      │ │
              │  │     └── Pod 2 (Flask + Gunicorn :8000)      │ │
              │  │  ConfigMap | Secret (dockerhub-secret)      │ │
              │  └─────────────────────────────────────────────┘ │
              │                                                  │
              │  Region: southcentralus | Node: Standard_B2pls_v2│
              └──────────────────────────────────────────────────┘

              ┌──────────────────────────────────────────────────┐
              │  Terraform gestiona:                             │
              │  Resource Group → AKS → IP Pública Estática     │
              │  → Namespace → Secret → NGINX Ingress (Helm)    │
              │  → Flask App (Helm Chart local)                  │
              └──────────────────────────────────────────────────┘
```

---

## Estructura del Proyecto

```
pruebatecnica-banco/
├── app/                              # Código fuente Flask
│   ├── app.py                        # Aplicación (2 endpoints: / y /health)
│   ├── requirements.txt              # Flask, flask-wtf, gunicorn, pytest
│   └── tests/
│       ├── __init__.py
│       └── test_app.py               # Tests unitarios (95% cobertura)
│
├── environment/                      # Manifiestos K8s (YAML plano)
│   ├── namespace.yaml                # Namespace flask-app
│   ├── configmap.yaml                # Variables de entorno
│   ├── deployment.yaml               # 2 réplicas, health probes, __IMAGE__
│   ├── service.yaml                  # ClusterIP :80 → :8000
│   ├── ingress.yaml                  # NGINX Ingress (endpoint externo)
│   └── nginx-ingress-values.yaml     # IP estática para NGINX Ingress Controller
│
├── helm/flask-app/                   # Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml                   # Valores por defecto
│   └── templates/
│       ├── _helpers.tpl
│       ├── NOTES.txt
│       ├── deployment.yaml
│       ├── service.yaml
│       └── ingress.yaml
│
├── terraform/                        # Infraestructura como Código
│   ├── main.tf                       # Providers (azurerm, helm, kubernetes)
│   ├── aks.tf                        # Resource Group + AKS + IP Pública Estática
│   ├── kubernetes.tf                 # Namespace, Secret, NGINX Ingress, Flask App
│   ├── variables.tf                  # Variables con defaults
│   ├── outputs.tf                    # Outputs (IP, FQDN, status)
│   └── terraform.tfvars              # Valores de la prueba
│
├── pipelines/templates/              # Templates del pipeline
│   ├── variables.yml                 # Variables compartidas
│   ├── ci.yml                        # Stage CI (5 jobs, PowerShell)
│   └── cd.yml                        # Stage CD (deploy AKS via Service Connection)
│
├── azure-pipelines.yml               # Pipeline orquestador (self-hosted Windows)
├── Dockerfile                        # Multi-stage build (Python 3.12, non-root)
├── sonar-project.properties          # SonarCloud config
├── .gitignore
└── .dockerignore
```

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
# http://localhost:8000
```

### 3. Tests y cobertura

```bash
cd app && python -m pytest tests/ -v --cov=. --cov-report=term-missing
# 3 tests, 95% coverage
```

---

## Infraestructura con Terraform

Terraform crea **toda la infraestructura desde cero**: Resource Group, AKS, IP pública estática, Namespace, Docker Secret, NGINX Ingress Controller y Flask App (via Helm).

```bash
cd terraform
az login
terraform init
terraform plan -var "docker_password=<TU_PASSWORD>"
terraform apply -var "docker_password=<TU_PASSWORD>"
```

### Recursos creados

| Recurso | Nombre | Descripción |
|---|---|---|
| Resource Group | `rg-pruebatecnica` | Grupo de recursos principal |
| AKS Cluster | `aks-pruebatecnica` | Kubernetes 1.33, 1 nodo ARM64 |
| Public IP | `pip-ingress-pruebatecnica` | IP estática `20.114.65.15` |
| Namespace | `flask-app` | Namespace de la aplicación |
| Secret | `dockerhub-secret` | Credenciales Docker Hub |
| Helm Release | `ingress-nginx` | NGINX Ingress Controller con IP estática |
| Helm Release | `flask-app` | Aplicación Flask (2 réplicas) |

### Verificar

```bash
az aks get-credentials --resource-group rg-pruebatecnica --name aks-pruebatecnica
kubectl get all -n flask-app
curl http://20.114.65.15
curl http://20.114.65.15/health
```

### Destruir

```bash
terraform destroy -var "docker_password=<TU_PASSWORD>"
```

---

## Pipeline CI/CD (Azure DevOps)

Pipeline en **2 stages** ejecutado en agente **self-hosted Windows** con **PowerShell**.

### Stage CI — Integración Continua (5 Jobs)

```
┌─ CI ─────────────────────────────────────────────────────────┐
│                                                              │
│  Job 1: SonarQube - Escenario Fallido (simulación)           │
│  Job 2: SonarQube - Escenario Exitoso                        │
│         → Tests + Cobertura (95%)                            │
│         → SonarCloud Analysis + Quality Gate                 │
│  Job 3: Docker Build & Push (multi-arch)             [dep:2] │
│         → Login → buildx (amd64+arm64) → Push Docker Hub    │
│  Job 4: Hola Mundo x10                              [dep:3] │  ← paralelo
│  Job 5: Crear 10 archivos con fecha                  [dep:3] │  ← paralelo
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Stage CD — Despliegue Continuo

```
┌─ CD ─────────────────────────────────────────────────────────┐
│                                                              │
│  1. Login a AKS via Service Connection (flask-app-aks)       │
│  2. Crear namespace + Docker Hub secret                      │
│  3. Configurar imagen en manifiestos (sed __IMAGE__)         │
│  4. kubectl apply (namespace, configmap, deployment,         │
│     service, ingress)                                        │
│  5. Verificar rollout + health check en IP estática          │
│                                                              │
│  NGINX Ingress Controller: gestionado por Terraform          │
│  (IP estática en environment/nginx-ingress-values.yaml)      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Variables de Pipeline (Azure DevOps UI → Pipelines → Variables)

| Variable | Tipo | Descripción |
|---|---|---|
| `DOCKER_PASS` | Secret | Contraseña/Token Docker Hub |
| `SONAR_TOKEN` | Secret | Token de SonarCloud |

### Service Connection

| Nombre | Tipo | Ámbito |
|---|---|---|
| `flask-app-aks` | Kubernetes | Namespace `flask-app` en `aks-pruebatecnica` |

---

## SonarCloud

Análisis de calidad con **SonarCloud** (`sonarcloud.io`).

| Escenario | Descripción | Quality Gate |
|---|---|---|
| 1 - Fallido | Tests sin cobertura (simulación educativa) | FAILED (esperado) |
| 2 - Exitoso | Tests con cobertura (95%) + análisis real | PASSED |

- **Organización:** `projectscamilo`
- **Project Key:** `projectscamilo_pruebatecnica`
- **Dashboard:** https://sonarcloud.io/dashboard?id=projectscamilo_pruebatecnica

---

## Seguridad

- **CSRF Protection:** `flask-wtf` CSRFProtect habilitado
- **Non-root container:** Dockerfile usa `USER appuser`
- **Secrets:** Nunca hardcodeados — variables secretas en Azure DevOps y `kubernetes.io/dockerconfigjson`
- **Multi-stage build:** Imagen final sin herramientas de compilación

---

## Kubernetes

### Manifiestos (`environment/`)

| Archivo | Recurso | Descripción |
|---|---|---|
| `namespace.yaml` | Namespace | `flask-app` |
| `configmap.yaml` | ConfigMap | `FLASK_HOST`, `FLASK_PORT` |
| `deployment.yaml` | Deployment | 2 réplicas, liveness/readiness probes |
| `service.yaml` | Service | ClusterIP :80 → :8000 |
| `ingress.yaml` | Ingress | NGINX Ingress, path `/` |
| `nginx-ingress-values.yaml` | Helm Values | IP estática del Ingress Controller |

### Deploy manual

```bash
kubectl apply -f environment/
kubectl get all -n flask-app
```

### Deploy con Helm

```bash
helm install flask-app helm/flask-app/ -n flask-app --create-namespace
helm upgrade flask-app helm/flask-app/ --set image.tag=<tag> -n flask-app
```

---

## API Endpoints

| Método | Ruta | Respuesta |
|---|---|---|
| GET | `/` | `{"message": "Hello, World!", "status": "running", "app": "pruebatecnica-banco"}` |
| GET | `/health` | `{"status": "healthy"}` (HTTP 200) |

---

## Stack Tecnológico

| Categoría | Tecnología | Versión |
|---|---|---|
| Lenguaje | Python | 3.12 |
| Framework | Flask | 3.1.0 |
| WSGI Server | Gunicorn | 23.0.0 |
| Testing | pytest + pytest-cov | 8.3.4 / 6.0.0 |
| Seguridad | flask-wtf (CSRF) | 1.2.2 |
| Container | Docker (multi-stage, multi-arch) | 24+ |
| Orquestación | Kubernetes (AKS) | 1.33 |
| IaC | Terraform | 1.5+ |
| Helm | Helm Chart | 3+ |
| CI/CD | Azure DevOps Pipelines | — |
| Calidad | SonarCloud | — |
| Cloud | Microsoft Azure (southcentralus) | — |

---

## Bonus Implementados

- [x] **Terraform IaC completa** — Toda la infraestructura desde cero (7 recursos)
- [x] **Helm Chart** — Templates reutilizables con `values.yaml`, `_helpers.tpl` y `NOTES.txt`
- [x] **Despliegue en nube Azure** — AKS en `southcentralus`
- [x] **IP pública estática** — NGINX Ingress Controller con IP fija (`20.114.65.15`)
- [x] **Pipeline con templates** — 2 stages reutilizables (CI + CD)
- [x] **Docker multi-arch** — `linux/amd64` + `linux/arm64` con buildx
- [x] **Multi-stage Dockerfile** — Imagen optimizada, non-root (`USER appuser`)
- [x] **SonarCloud** — Análisis de calidad + Quality Gate + cobertura 95%
- [x] **CSRF Protection** — `flask-wtf` CSRFProtect
- [x] **Service Connection** — Autenticación segura al AKS desde pipeline
- [x] **Secrets gestionados** — Variables secretas en Azure DevOps, nunca en código
- [x] **Health checks** — Liveness + readiness probes en K8s

---

## Limpieza de Recursos

```bash
# Terraform
cd terraform && terraform destroy -var "docker_password=<TU_PASSWORD>"

# O via Azure CLI
az group delete --name rg-pruebatecnica --yes --no-wait
```
