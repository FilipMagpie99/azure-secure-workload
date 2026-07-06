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