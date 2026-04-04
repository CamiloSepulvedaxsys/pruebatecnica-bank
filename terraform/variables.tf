variable "subscription_id" {
  description = "ID de la suscripción de Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-pruebatecnica"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "southcentralus"
}

variable "cluster_name" {
  description = "Nombre del clúster AKS"
  type        = string
  default     = "aks-pruebatecnica"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el clúster AKS"
  type        = string
  default     = "flask-app"
}

variable "node_count" {
  description = "Número de nodos del clúster"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "Tamaño de VM para los nodos"
  type        = string
  default     = "Standard_B2pls_v2"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.33"
}

# =============================================================================
# Docker Hub credentials (para imagePullSecret en K8s)
# =============================================================================
variable "docker_server" {
  description = "Docker registry server"
  type        = string
  default     = "https://index.docker.io/v1/"
}

variable "docker_username" {
  description = "Docker Hub username"
  type        = string
  default     = "camiloxsys"
}

variable "docker_password" {
  description = "Docker Hub password"
  type        = string
  sensitive   = true
}

variable "docker_image" {
  description = "Imagen Docker completa (user/image)"
  type        = string
  default     = "camiloxsys/flask-app"
}

variable "docker_tag" {
  description = "Tag de la imagen Docker"
  type        = string
  default     = "latest"
}
