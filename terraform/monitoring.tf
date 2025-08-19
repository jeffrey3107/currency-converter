# terraform/monitoring.tf - Monitoring and ArgoCD setup

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# Create monitoring namespace
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }

  depends_on = [module.eks]
}

# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }

  depends_on = [module.eks]
}

# Prometheus using Helm
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "51.2.0"
  timeout    = 600

  values = [
    yamlencode({
      alertmanager = {
        enabled = true
      }
      grafana = {
        enabled = true
        adminPassword = "admin123"
        service = {
          type = "LoadBalancer"
        }
      }
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues = false
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp2"
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "20Gi"
                  }
                }
              }
            }
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.monitoring]
}

# ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = "5.46.7"
  timeout    = 600

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        }
        extraArgs = [
          "--insecure"
        ]
      }
      configs = {
        repositories = {
          currency-converter = {
            url = "https://github.com/jeffrey3107/currency-converter.git"
            type = "git"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# AWS Load Balancer Controller
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2"
  timeout    = 600

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  depends_on = [module.eks]
}
