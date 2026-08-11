variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id_app" {
  type = string
}


variable "snet_pe_id" {
  type = string
}

variable "dns_zone_id" {
  type = string
}

variable "dns_zone_id_db" {
  type = string
}

variable "subnet_id_appgw" {
  type = string
}

variable "dev_ip" {
  type = string
}

variable "pg_entra_admin_object_id" {
  description = "Object ID of the PostgreSQL Entra administrator"
  type        = string
}

variable "pg_entra_admin_upn" {
  description = "UPN of the PostgreSQL Entra administrator"
  type        = string
}