terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # State is a local file (terraform.tfstate in this folder): nothing to create beforehand.
  # Keep it until you run `tofu destroy`, since it is how OpenTofu finds the VMs again.
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id

  # The provider registers the resource providers it needs, so you don't run `az provider register`.
  # "core" covers Compute, Network and Storage; the auto-shutdown schedule also needs DevTestLab.
  resource_provider_registrations = "core"
  resource_providers_to_register  = ["Microsoft.DevTestLab"]
}
