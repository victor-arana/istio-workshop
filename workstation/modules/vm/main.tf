# Instructor's subscription: only the workshop VMs live here. Each attendee's AKS cluster is created
# from their VM in the attendee's OWN subscription, after they sign in with `az login`.

locals {
  tags = {
    purpose      = "istio-workshop"
    delete_after = var.delete_after
  }

  # Bare VM, or a VM that installs the tools on first boot.
  cloud_init = "${path.module}/${var.install_tools ? "cloud-init-preinstalled.yaml" : "cloud-init-minimal.yaml"}"
}

resource "azurerm_resource_group" "ws" {
  name     = "rg-istio-ws-vms"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "ws" {
  name                = "vnet-istio-ws"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  address_space       = ["10.60.0.0/24"]
  tags                = local.tags
}

resource "azurerm_subnet" "ws" {
  name                 = "snet-vms"
  resource_group_name  = azurerm_resource_group.ws.name
  virtual_network_name = azurerm_virtual_network.ws.name
  address_prefixes     = ["10.60.0.0/24"]
}

resource "azurerm_network_security_group" "ws" {
  name                = "nsg-istio-ws-vms"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  tags                = local.tags

  security_rule {
    name                       = "ssh-from-allowed-ranges"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ssh_allowed_cidrs
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "ws" {
  subnet_id                 = azurerm_subnet.ws.id
  network_security_group_id = azurerm_network_security_group.ws.id
}

resource "azurerm_public_ip" "ws" {
  for_each            = var.attendees
  name                = "pip-istio-ws-${each.key}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "ws" {
  for_each            = var.attendees
  name                = "nic-istio-ws-${each.key}"
  location            = azurerm_resource_group.ws.location
  resource_group_name = azurerm_resource_group.ws.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.ws.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ws[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "ws" {
  for_each                        = var.attendees
  name                            = "vm-istio-ws-${each.key}"
  location                        = azurerm_resource_group.ws.location
  resource_group_name             = azurerm_resource_group.ws.name
  size                            = var.vm_size
  admin_username                  = "workshop"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.ws[each.key].id]

  admin_ssh_key {
    username   = "workshop"
    public_key = each.value
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  # No managed identity: the VM holds no Azure permissions. The attendee signs in with `az login`.

  custom_data = base64encode(templatefile(local.cloud_init, {
    attendee           = each.key
    repo_url           = var.repo_url
    istio_version      = var.istio_version
    location           = var.aks_location != "" ? var.aks_location : var.location
    kubernetes_version = var.kubernetes_version
    aks_vm_size        = var.aks_vm_size
    aks_node_count     = var.aks_node_count
    delete_after       = var.delete_after
  }))

  tags = merge(local.tags, { attendee = each.key })
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "ws" {
  for_each              = var.attendees
  virtual_machine_id    = azurerm_linux_virtual_machine.ws[each.key].id
  location              = azurerm_resource_group.ws.location
  enabled               = true
  daily_recurrence_time = var.shutdown_time
  timezone              = var.shutdown_timezone

  notification_settings {
    enabled = false
  }
}
