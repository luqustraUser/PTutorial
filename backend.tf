terraform {
  backend "azurerm" {
    resource_group_name  = "PTutorial-RG"
    storage_account_name = "ptutorial123"
    container_name       = "ptstate"
    key                  = "terraform.tfstate"
    subscription_id      = "f7ebe6c1-5970-43d1-83d7-2a3ffdf07b74"  # Check this!
  }
}
