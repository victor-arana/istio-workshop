# Most of these are exported as TF_VAR_* on the workshop VM, so `tofu apply` needs no arguments.
# The subscription is not a variable: it is the one you selected with `az login` and exported as
# ARM_SUBSCRIPTION_ID.

variable "attendee" {
  description = "Attendee name, such as attendee-01"
  type        = string
}

variable "location" {
  description = "Azure region for your resource group and cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Pinned version from `az aks get-versions`"
  type        = string
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v5"
}

variable "node_count" {
  type    = number
  default = 3
}

variable "delete_after" {
  description = "Date written to the delete_after tag, e.g. 2026-12-01"
  type        = string
}
