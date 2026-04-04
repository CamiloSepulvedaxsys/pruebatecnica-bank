variable "resource_group_name" {
  description = "Nombre del Resource Group"
  type        = string
  default     = "rg-pruebatecnica"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus2"
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
  default     = 2
}

variable "vm_size" {
  description = "Tamaño de VM para los nodos"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes"
  type        = string
  default     = "1.29"
}

variable "acr_name" {
  description = "Nombre del Azure Container Registry"
  type        = string
  default     = "acrpruebatecnica"
}
