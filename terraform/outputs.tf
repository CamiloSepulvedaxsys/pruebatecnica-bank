output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Nombre del Resource Group"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Nombre del clúster AKS"
}

output "aks_cluster_fqdn" {
  value       = azurerm_kubernetes_cluster.aks.fqdn
  description = "FQDN del clúster AKS"
}

output "aks_kube_config" {
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
  description = "kubeconfig para conectarse al clúster"
}

output "aks_get_credentials_command" {
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.aks.name}"
  description = "Comando para obtener credenciales del clúster"
}

output "helm_release_status" {
  value       = helm_release.flask_app.status
  description = "Estado del despliegue Helm"
}

output "ingress_controller_status" {
  value       = helm_release.nginx_ingress.status
  description = "Estado del NGINX Ingress Controller"
}
