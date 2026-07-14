variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}


variable "app_service_ids" {
  type = map(string)
}

variable "subscription_id" {
  type = string
}

variable "postgres_server_id" {
  type = string
}

variable "secure_workload_appgw_id" {
  type = string
}