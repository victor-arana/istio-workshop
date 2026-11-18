output "kube_config" {
  value     = azurerm_kubernetes_cluster.ws.kube_config_raw
  sensitive = true
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.ws.name
}

output "resource_group" {
  value = azurerm_resource_group.ws.name
}

output "get_credentials" {
  value = "az aks get-credentials -g ${azurerm_resource_group.ws.name} -n ${azurerm_kubernetes_cluster.ws.name} --overwrite-existing"
}
