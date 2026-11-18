terraform {
  required_version = ">= 1.8"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# Stack 1 outputs the kubeconfig; this stack reads it from stack 1's local state file instead of
# configuring providers from a cluster created in the same apply.
data "terraform_remote_state" "cluster" {
  backend = "local"
  config = {
    path = "${path.module}/../stack-1-cluster/terraform.tfstate"
  }
}

locals {
  kc = yamldecode(data.terraform_remote_state.cluster.outputs.kube_config)
  cluster = {
    host                   = local.kc.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kc.clusters[0].cluster["certificate-authority-data"])
    client_certificate     = base64decode(local.kc.users[0].user["client-certificate-data"])
    client_key             = base64decode(local.kc.users[0].user["client-key-data"])
  }
}

provider "kubernetes" {
  host                   = local.cluster.host
  cluster_ca_certificate = local.cluster.cluster_ca_certificate
  client_certificate     = local.cluster.client_certificate
  client_key             = local.cluster.client_key
}

provider "helm" {
  kubernetes {
    host                   = local.cluster.host
    cluster_ca_certificate = local.cluster.cluster_ca_certificate
    client_certificate     = local.cluster.client_certificate
    client_key             = local.cluster.client_key
  }
}
