variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
}
variable "resource_group_name" {
  description = "The name of the resource group to deploy resources in."
  type        = string
}
variable "vnet_id" {
  description = "The ID of the virtual network to deploy DNS resources in."
  type        = string
}