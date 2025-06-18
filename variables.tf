variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "AustraliaEast"
}

variable "username" {
  description = "Admin username for virtual machines"
  default     = "azureuser"
}

variable "admin_password" {
  type      = string
  default   = null
  sensitive = true

  validation {
    condition     = var.admin_password == null || length(var.admin_password) >= 12
    error_message = "Admin password must be at least 12 characters if provided."
  }
}

variable "vmsize" {
  description = "Size of the Azure virtual machines"
  default     = "Standard_DS1_v2"
}
