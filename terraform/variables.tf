variable "identifier" {
  type = string
}

variable "location" {
  type = string
}

variable "modules" {
  type = list(string)
}

variable "access_via_private_endpoint_function_package_url" {
  type = string
}

variable "vm_admin_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "vm_admin_password" {
  type      = string
  default   = ""
  sensitive = true
}
