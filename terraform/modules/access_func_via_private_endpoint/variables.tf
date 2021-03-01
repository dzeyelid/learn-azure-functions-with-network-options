variable "identifier" {
  type = string
}

variable "location" {
  type = string
}

variable "function_package_url" {
  type = string
}

variable "vm" {
  type = object({
    size              = string
    publisher         = string
    offer             = string
    sku               = string
    disk_account_type = string
    disk_size_gb      = number
  })

  default = {
    size              = "Standard_B4ms"
    publisher         = "MicrosoftWindowsServer"
    offer             = "WindowsServer"
    sku               = "2019-Datacenter"
    disk_account_type = "Premium_LRS"
    disk_size_gb      = 127
  }
}

variable "vm_admin_username" {
  type      = string
  sensitive = true
}

variable "vm_admin_password" {
  type      = string
  sensitive = true
}
