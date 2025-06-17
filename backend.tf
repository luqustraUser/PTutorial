terraform {
  backend "azurerm" {
    resource_group_name  = "PTutorial-RG"
    storage_account_name = "ptutorial123"
    container_name       = "ptstate"
    key                  = "terraform.tfstate"   # The state file name, can be project specific
  }
}
