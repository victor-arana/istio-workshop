variable "istio_version" {
  description = "Must match istioctl, the docs and the sample manifests (exported as TF_VAR_istio_version on the VM)"
  type        = string
  default     = "1.32.0"
}

variable "workshop_domain" {
  description = "Fake domain for Host headers and manifests"
  type        = string
  default     = "workshop.example.com"
}
