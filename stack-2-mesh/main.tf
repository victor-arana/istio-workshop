locals {
  istio_repo = "https://istio-release.storage.googleapis.com/charts"
  # Addons are versioned by Istio's minor release branch.
  istio_minor = join(".", slice(split(".", var.istio_version), 0, 2))
  addons_url  = "https://raw.githubusercontent.com/istio/istio/release-${local.istio_minor}/samples/addons"
  repo_root   = abspath("${path.module}/..")
}

# The kubectl steps below use the kubeconfig that `az aks get-credentials` wrote (lab 0).

# ---- namespaces
resource "kubernetes_namespace" "apps" {
  metadata {
    name   = "apps"
    labels = { "istio-injection" = "enabled" }
  }
  depends_on = [helm_release.istiod]
}

resource "kubernetes_namespace" "external" {
  metadata {
    name = "external" # no injection: stands in for a system outside the mesh
  }
}

# ---- Istio (upstream, via Helm)
resource "helm_release" "istio_base" {
  name             = "istio-base"
  repository       = local.istio_repo
  chart            = "base"
  namespace        = "istio-system"
  create_namespace = true
  version          = var.istio_version
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = local.istio_repo
  chart      = "istiod"
  namespace  = "istio-system"
  version    = var.istio_version
  wait       = true
  depends_on = [helm_release.istio_base]
}

resource "helm_release" "ingress_gateway" {
  name       = "istio-ingress"
  repository = local.istio_repo
  chart      = "gateway"
  namespace  = "istio-system"
  version    = var.istio_version
  depends_on = [helm_release.istiod]

  # Keep the client source IP so the IP-range lab works.
  set {
    name  = "service.externalTrafficPolicy"
    value = "Local"
  }
}

# ---- Kiali and Prometheus (demo-grade sample addons)
resource "terraform_data" "addons" {
  depends_on = [helm_release.istiod]
  provisioner "local-exec" {
    command = "kubectl apply -f ${local.addons_url}/prometheus.yaml -f ${local.addons_url}/kiali.yaml"
  }
}

# ---- Certificates, sample apps, mock core API
resource "terraform_data" "certificates" {
  depends_on = [kubernetes_namespace.apps, kubernetes_namespace.external]
  provisioner "local-exec" {
    environment = { CERT_DIR = "${local.repo_root}/.certs" }
    command     = "${local.repo_root}/scripts/certificates.sh"
  }
}

resource "terraform_data" "sample_apps" {
  depends_on = [helm_release.istiod, terraform_data.certificates, kubernetes_namespace.apps]
  provisioner "local-exec" {
    command = "kubectl apply -f ${local.repo_root}/labs/apps/ && kubectl -n external rollout status deploy/core-api --timeout=120s"
  }
}
