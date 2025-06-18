terraform {
  required_version = ">= 0.12"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {
}

# ================================
# Random Password Generator (Optional)
# ================================

# Generate a random password if no password is provided via variable
resource "random_password" "password" {
  count   = var.admin_password == null ? 1 : 0
  length  = 20
  special = true
}

locals {
  password = var.admin_password != null ? var.admin_password : try(random_password.password[0].result, null)
}
