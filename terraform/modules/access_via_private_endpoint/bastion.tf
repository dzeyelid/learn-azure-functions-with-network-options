locals {
  bastion_name = "bastion-${local.identifier_in_module}"
}

resource "azurerm_public_ip" "for_bastion" {
  name                = "pip-${local.identifier_in_module}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_bastion_host" "main" {
  name                = local.bastion_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "ipConfigBastion"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.for_bastion.id
  }
}
