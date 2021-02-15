resource "azurerm_network_interface" "vm" {
  name                = "nic-${local.identifier_in_module}-vm"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = "vm-${local.identifier_in_module}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm.size

  computer_name  = "vm-main"
  admin_username = var.vm_admin_username
  admin_password = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.vm.disk_account_type
    disk_size_gb         = var.vm.disk_size_gb
  }

  source_image_reference {
    publisher = var.vm.publisher
    offer     = var.vm.offer
    sku       = var.vm.sku
    version   = "latest"
  }
}
