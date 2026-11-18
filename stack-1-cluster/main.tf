locals {
  tags = {
    purpose      = "istio-workshop"
    attendee     = var.attendee
    delete_after = var.delete_after
  }
}

resource "azurerm_resource_group" "ws" {
  name     = "rg-istio-ws-${var.attendee}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_kubernetes_cluster" "ws" {
  name                = "aks-istio-ws-${var.attendee}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  dns_prefix          = "istiows-${var.attendee}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  default_node_pool {
    name       = "system"
    vm_size    = var.vm_size
    node_count = var.node_count
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}
