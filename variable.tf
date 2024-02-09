variable "labelPrefix" {
  description = "Prefix for resource labels"
  type        = string
  // Default value is my college name.
  default     = "kuyg0002"
}

variable "region" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "East US"
}

variable "admin_username" {
  description = "The admin username for the VM."
  type        = string
  default     = "azureadmin"
}


