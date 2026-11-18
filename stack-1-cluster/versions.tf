terraform {
  required_version = ">= 1.8"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# Runs on the workshop VM, in the ATTENDEE's own subscription. Authentication is the attendee's
# `az login`, and the subscription comes from ARM_SUBSCRIPTION_ID (see lab 0).
provider "azurerm" {
  features {}
  resource_provider_registrations = "none" # registered once in lab 0 with `az provider register`
}
