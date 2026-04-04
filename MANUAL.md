# MANUAL: Cómo volver a subir todo desde cero

Este manual te permite recrear **toda la infraestructura y el pipeline** desde cero después de haber eliminado los recursos de Azure.

---

## Datos de la cuenta (referencia)

| Dato | Valor |
|------|-------|
| Azure Subscription | `c390f2ed-5732-401f-9cca-191c601cc20e` |
| Azure Tenant | `b1ba85eb-a253-4467-9ee8-d4f8ed4df300` |
| Service Principal App ID | `0ef6223e-8b21-45a3-b88c-1a7b66acb3d0` |
| Azure DevOps Org | `https://dev.azure.com/projectscamilo` |
| Azure DevOps Project | `pruebatecnica-banco` |
| Docker Hub User | `camiloxsys` |
| Agent Pool | `SelfHosted` |
| Agent Location | `C:\azagent2` |

---

## PASO 1: Iniciar Docker Desktop

Abrir **Docker Desktop** y esperar a que el engine esté corriendo.

```powershell
# Verificar que Docker está listo
docker info
```

---

## PASO 2: Iniciar SonarQube

```powershell
docker start sonarqube
# Esperar ~30 segundos a que arranque
# Verificar: http://localhost:9000
# Credenciales: admin / Admin12345**
```

---

## PASO 3: Iniciar el Azure DevOps Agent

```powershell
cd C:\azagent2
.\run.cmd
# Dejar esta terminal abierta (el agente corre en foreground)
# Verificar en Azure DevOps > Project Settings > Agent Pools > SelfHosted
```

---

## PASO 4: Login en Azure CLI

```powershell
# Opción A: Login interactivo (recomendado)
az login

# Opción B: Login con Service Principal
az login --service-principal `
  -u "0ef6223e-8b21-45a3-b88c-1a7b66acb3d0" `
  -p "<SP_PASSWORD>" `
  --tenant "b1ba85eb-a253-4467-9ee8-d4f8ed4df300"

az account set --subscription "c390f2ed-5732-401f-9cca-191c601cc20e"
```

---

## PASO 5: Crear infraestructura con Terraform

```powershell
cd c:\Users\CAMILO SEPULVEDA\Documents\camilo.projects\pruebatecnica-banco\terraform

# Inicializar providers
terraform init

# Ver qué se va a crear
terraform plan

# Crear todo (te pedirá docker_password)
terraform apply
# Ingresa tu password de Docker Hub cuando lo pida

# Tiempo estimado: ~5-8 minutos (el AKS tarda)
```

Esto crea automáticamente:
- Resource Group `rg-pruebatecnica`
- AKS Cluster `aks-pruebatecnica` (1 nodo Standard_B2pls_v2)
- Namespace `flask-app` en Kubernetes
- Secret `dockerhub-secret` para pull de imágenes
- Helm Release con la app Flask desplegada (2 réplicas + LoadBalancer)

---

## PASO 6: Obtener credenciales y verificar AKS

```powershell
# Obtener kubeconfig
az aks get-credentials --resource-group rg-pruebatecnica --name aks-pruebatecnica

# Verificar que todo está corriendo
kubectl get all -n flask-app

# Ver la IP externa del LoadBalancer
kubectl get svc flask-app-service -n flask-app
# Puede tardar 1-2 minutos en asignar la IP

# Probar la app
curl http://<EXTERNAL-IP>/
curl http://<EXTERNAL-IP>/health
```

---

## PASO 7: Ejecutar el Pipeline (opcional)

Si quieres correr el pipeline CI/CD completo:

```powershell
# Asegurarse de que SonarQube esté corriendo (PASO 2)
# Asegurarse de que el Agent esté corriendo (PASO 3)

# Opción A: Hacer un push para disparar automáticamente
cd c:\Users\CAMILO SEPULVEDA\Documents\camilo.projects\pruebatecnica-banco
git add -A
git commit -m "trigger pipeline"
git push azure main

# Opción B: Disparar manualmente desde Azure DevOps
# Ir a: Azure DevOps > Pipelines > pruebatecnica-banco-ci > Run Pipeline
```

Las variables del pipeline ya están configuradas en Azure DevOps:
- `DOCKER_PASS` (secret)
- `SONAR_TOKEN` (secret)
- `AZURE_SP_APP_ID` (secret)
- `AZURE_SP_SECRET` (secret)
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

---

## PASO 8: Verificación final

```powershell
# 1. App respondiendo en AKS
$ip = kubectl get svc flask-app-service -n flask-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
Invoke-RestMethod "http://$ip/"
Invoke-RestMethod "http://$ip/health"

# 2. SonarQube
# http://localhost:9000/dashboard?id=pruebatecnica

# 3. Pipeline en Azure DevOps
# https://dev.azure.com/projectscamilo/pruebatecnica-banco/_build

# 4. Docker Hub
# https://hub.docker.com/r/camiloxsys/flask-app
```

---

## APAGAR TODO (cuando termines)

### a) Eliminar infraestructura Azure

```powershell
cd terraform
terraform destroy
# Confirmar con "yes"
# Elimina: AKS, RG, namespace, secret, helm release
```

O directamente:
```powershell
az group delete --name rg-pruebatecnica --yes --no-wait
```

### b) Detener servicios locales

```powershell
# SonarQube
docker stop sonarqube

# Azure Agent (Ctrl+C en la terminal donde corre, o:)
Get-Process Agent.Listener | Stop-Process -Force

# Minikube (si lo usaste)
minikube stop
```

---

## Resumen de tiempos

| Paso | Tiempo aprox. |
|------|--------------|
| Docker Desktop | ~1 min |
| SonarQube | ~30 seg |
| Azure Agent | ~10 seg |
| `terraform apply` | ~5-8 min |
| IP del LoadBalancer | ~1-2 min |
| Pipeline completo | ~5-7 min |
| **Total** | **~15 min** |

---

## Troubleshooting

### Terraform falla por región no permitida
Tu suscripción Azure for Students solo permite: `westus3`, `canadacentral`, `northcentralus`, `southcentralus`, `chilecentral`. El tfvars ya usa `southcentralus`.

### Terraform falla por VM size no permitida
El tfvars usa `Standard_B2pls_v2` (ARM64, el más barato permitido). Si da error, probar con `Standard_B2s_v2`.

### Pipeline falla en "az: no se reconoce"
El CD template ya incluye un paso que agrega `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin` al PATH. Si sigue fallando, verificar que Azure CLI está instalado en la máquina del agente.

### SonarQube no arranca
```powershell
docker logs sonarqube --tail 20
# Si da error de memoria, aumentar en Docker Desktop: Settings > Resources > Memory > 4GB
```

### Agent no se conecta
```powershell
cd C:\azagent2
# Si da error de token, reconfigurar:
.\config.cmd remove
.\config.cmd
# Usar PAT de Azure DevOps
```
