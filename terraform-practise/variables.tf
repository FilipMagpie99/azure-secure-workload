variable "location" {
  description = "Dozwolny region dla zasobów projektu"
  type        = string
  default     = "polandcentral"
  validation {
    condition     = contains(["polandcentral"], var.location)
    error_message = "Niepoprawna lokalizacja. Dozwolona lokalizacja to polandcentral"
  }
}

variable "resource_group_name" {
  description = "Nazwa resource grupy"
  type        = string
  default     = "RG-TF-LAB2"
}

