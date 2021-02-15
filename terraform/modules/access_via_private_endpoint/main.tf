locals {
  module_name          = "access-via-pe"
  identifier_in_module = "${var.identifier}-${local.module_name}"
  subnet_name          = "snet-${local.identifier_in_module}"
  app_plan_name        = "plan-${local.identifier_in_module}"
  vnet_address_space   = "10.0.0.0/16"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.identifier}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.identifier}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [local.vnet_address_space]
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 0)]
}

resource "azurerm_subnet" "for_private_endpoint" {
  name                                           = "${local.subnet_name}-for-private-endpoint"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.main.name
  address_prefixes                               = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 1)]
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "for_func" {
  name                 = "${local.subnet_name}-for-func"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 2)]
  service_endpoints    = ["Microsoft.Storage", "Microsoft.AzureCosmosDB"]

  delegation {
    name = "Delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

resource "azurerm_subnet" "vm" {
  name                 = "${local.subnet_name}-vm"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 3)]
  service_endpoints    = ["Microsoft.Web"]
}
