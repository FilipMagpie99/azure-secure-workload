variable "location" {
  description = "Azure region where the resources will be created"
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "name of the resource group"
  type        = string
  default     = "rg-secure-workload"
}

variable "dev_ip" {
  description = "IP address of the developer machine for access to the App Services"
  type        = string
}