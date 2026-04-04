terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  # Estado local (para pruebas).
  # En producción usar backend remoto (Azure Storage, Terraform Cloud, etc.)
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
