variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "AustraliaEast"
}

variable "username" {
  description = "Admin username for virtual machines"
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the virtual machines"
  type        = string
  sensitive   = true
  default     = null

  validation {
    condition     = var.admin_password == null || try(length(trimspace(var.admin_password)) >= 12, true)
    error_message = "If provided, the admin password must be at least 12 characters long."
  }
}

variable "vmsize" {
  description = "Size of the Azure virtual machines"
  default     = "Standard_DS1_v2"
}
