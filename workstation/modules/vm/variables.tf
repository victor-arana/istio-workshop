variable "location" {
  type = string
}

variable "attendees" {
  description = "Attendee name to SSH public key, e.g. attendee-01 = \"ssh-ed25519 AAAA...\". Names: lowercase letters, digits, hyphens"
  type        = map(string)
}

variable "ssh_allowed_cidrs" {
  description = "Ranges allowed to SSH, such as the office or VPN egress"
  type        = list(string)
}

variable "repo_url" {
  description = "Git URL of this repository: cloned on first boot (preinstalled) or by the attendee (minimal)"
  type        = string
}

variable "delete_after" {
  description = "Date written to the delete_after tag, e.g. 2026-12-01"
  type        = string
}

variable "install_tools" {
  description = "true: install git, az, kubectl, helm, tofu and istioctl on first boot and clone the repository. false: leave the VM bare"
  type        = bool
}

variable "vm_size" {
  description = "Workshop VM size"
  type        = string
  default     = "Standard_B2s"
}

# Settings exported on the VM; the attendee's `tofu apply` uses them for the AKS cluster.
variable "kubernetes_version" {
  description = "AKS version, from `az aks get-versions`"
  type        = string
}

variable "aks_location" {
  description = "Region where attendees create their AKS clusters, in their own subscription. Empty = same as the VMs"
  type        = string
  default     = ""
}

variable "aks_vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "aks_node_count" {
  type    = number
  default = 3
}

variable "istio_version" {
  type    = string
  default = "1.32.0"
}

variable "shutdown_time" {
  description = "Daily auto-shutdown time, HHMM"
  type        = string
  default     = "2100"
}

variable "shutdown_timezone" {
  description = "Windows time zone ID for shutdown_time, e.g. \"UTC\" or \"Central America Standard Time\" (UTC-6, no daylight saving)"
  type        = string
  default     = "UTC"
}
