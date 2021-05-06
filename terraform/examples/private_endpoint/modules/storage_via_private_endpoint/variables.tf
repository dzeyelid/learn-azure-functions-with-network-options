variable "identifier" {
  type = string
}

variable "location" {
  type = string
}

variable "function_package_url" {
  type = string
}

variable "terraform" {
  type = object({
    virtual_network_name = string
    resource_group_name  = string
  })
}
