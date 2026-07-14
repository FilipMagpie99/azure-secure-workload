variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "vnet_name" {
  type    = string
  default = "secure-workload-vnet"
}

variable "appgw_identity_id" {
  type = string
}

variable "appgw_cert_versionless_secret_id" {
  type = string
}

