variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "vnet_address_space" {
  description = "Adresacja sieci wirtualnej"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}