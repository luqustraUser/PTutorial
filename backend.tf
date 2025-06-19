terraform {
  backend "azurerm" {
    resource_group_name  = "PTutorial-RG"
    storage_account_name = "ptutorial123"
    container_name       = "ptstate"
    key                  = "terraform.tfstate"
    subscription_id      = "b13f0293-708e-4b14-9ae7-a3a36e3dfa2a" # Check this!
  }
}