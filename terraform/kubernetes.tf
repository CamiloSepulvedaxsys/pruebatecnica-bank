# =============================================================================
# Kubernetes Resources - Namespace, Secret, Helm Release
# Se despliega la app Flask al clúster AKS usando el Helm chart local
# =============================================================================

# =============================================================================
# Namespace
# =============================================================================
resource "kubernetes_namespace" "flask_app" {
  metadata {
    name = "flask-app"
    labels = {
      app         = "flask-app"
      environment = "production"
      managed_by  = "terraform"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# =============================================================================
# Docker Hub Secret (imagePullSecret)
# =============================================================================
resource "kubernetes_secret" "dockerhub" {
  metadata {
    name      = "dockerhub-secret"
    namespace = kubernetes_namespace.flask_app.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.docker_server) = {
          username = var.docker_username
          password = var.docker_password
          auth     = base64encode("${var.docker_username}:${var.docker_password}")
        }
      }
    })
  }
}

# =============================================================================
# NGINX Ingress Controller (vía Helm)
# =============================================================================
resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.10.1"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.replicaCount"
    value = "1"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# =============================================================================
# Helm Release - Flask App
# =============================================================================
resource "helm_release" "flask_app" {
  name      = "flask-app"
  chart     = "${path.module}/../helm/flask-app"
  namespace = kubernetes_namespace.flask_app.metadata[0].name

  set {
    name  = "image.repository"
    value = var.docker_image
  }

  set {
    name  = "image.tag"
    value = var.docker_tag
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_namespace.flask_app,
    kubernetes_secret.dockerhub,
    helm_release.nginx_ingress
  ]
}
