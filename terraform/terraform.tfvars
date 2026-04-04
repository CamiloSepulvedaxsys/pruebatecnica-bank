# =============================================================================
# terraform.tfvars - Valores para la prueba técnica
# NOTA: No subir a git si contiene secrets. Usar TF_VAR_* en CI/CD.
# =============================================================================

subscription_id = "c390f2ed-5732-401f-9cca-191c601cc20e"

# Azure
resource_group_name = "rg-pruebatecnica"
location            = "southcentralus"

# AKS
cluster_name       = "aks-pruebatecnica"
dns_prefix         = "flask-app"
node_count         = 1
vm_size            = "Standard_B2pls_v2"
kubernetes_version = "1.33"

# Docker Hub
docker_username = "camiloxsys"
docker_image    = "camiloxsys/flask-app"
docker_tag      = "latest"
