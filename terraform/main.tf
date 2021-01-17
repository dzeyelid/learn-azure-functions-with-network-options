terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.42"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  vnet_address_space = "10.0.0.0/16"
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

module "service_endpint" {
  source = "./modules/service_endpoint"

  identifier           = var.identifier
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  subnet_netnum        = 0

  depends_on = [
    azurerm_resource_group.main,
    azurerm_virtual_network.main
  ]
}

resource "azurerm_resource_group" "west_europe" {
  name     = "rg-${var.identifier}-west-europe"
  location = "westeurope"
}

resource "azurerm_virtual_network" "west_europe" {
  name                = "vnet-${var.identifier}-west-europe"
  location            = azurerm_resource_group.west_europe.location
  resource_group_name = azurerm_resource_group.west_europe.name
  address_space       = [local.vnet_address_space]
}

module "service_endpint_west_eu" {
  source = "./modules/service_endpoint_west_eu"

  identifier           = "${var.identifier}-we"
  resource_group_name  = azurerm_resource_group.west_europe.name
  virtual_network_name = azurerm_virtual_network.west_europe.name
  subnet_netnum        = 0

  depends_on = [
    azurerm_resource_group.west_europe,
    azurerm_virtual_network.west_europe
  ]
}
