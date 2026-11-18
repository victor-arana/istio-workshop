module "vm" {
  source = "../modules/vm"

  install_tools = true

  location           = var.location
  aks_location       = var.aks_location
  attendees          = var.attendees
  ssh_allowed_cidrs  = var.ssh_allowed_cidrs
  repo_url           = var.repo_url
  delete_after       = var.delete_after
  vm_size            = var.vm_size
  kubernetes_version = var.kubernetes_version
  aks_vm_size        = var.aks_vm_size
  aks_node_count     = var.aks_node_count
  istio_version      = var.istio_version
  shutdown_time      = var.shutdown_time
  shutdown_timezone  = var.shutdown_timezone
}
