terraform {
  backend "azurerm" {
    resource_group_name  = "Terraform-RG"
    storage_account_name = "tfstateterraform1234"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
