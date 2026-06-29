variable "location" {
  description = "Azure region where the resources will be created"
  type        = string
  default     = "polandcentral"
}

variable "resource_group_name" {
  description = "name of the resource group"
  type        = string
  default     = "rg-secure-workload"
}