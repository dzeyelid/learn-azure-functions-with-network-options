data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  resource_group_name = data.azurerm_resource_group.main.name
}

locals {
  module_name    = "service-endpoint"
  subnet_name    = "snet-${var.identifier}-${local.module_name}"
  app_plan_name  = "plan-${var.identifier}-${local.module_name}"
  function_name  = "func-${var.identifier}-${local.module_name}"
  storage_suffix = "se"
}

resource "azurerm_subnet" "module" {
  name                 = local.subnet_name
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(data.azurerm_virtual_network.main.address_space[0], 8, var.subnet_netnum)]
  service_endpoints    = ["Microsoft.Storage"]

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

resource "azurerm_app_service_plan" "module" {
  name                = local.app_plan_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_function_app" "module" {
  name                       = local.function_name
  location                   = data.azurerm_resource_group.main.location
  resource_group_name        = data.azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.module.id
  storage_account_name       = azurerm_storage_account.for_func.name
  storage_account_access_key = azurerm_storage_account.for_func.primary_access_key
  version                    = "~3"

  site_config {
    always_on = true
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.for_fileshare.primary_connection_string
    WEBSITE_CONTENTSHARE                     = local.function_name
    FUNCTIONS_WORKER_RUNTIME                 = "dotnet"
    WEBSITE_VNET_ROUTE_ALL                   = 1
    # WEBSITE_CONTENTOVERVNET = 1
    # WEBSITE_DNS_SERVER = 
    WEBSITE_RUN_FROM_PACKAGE = 1
    StorageWebHostForFunc    = azurerm_storage_account.for_func.primary_web_host
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "module" {
  app_service_id = azurerm_function_app.module.id
  subnet_id      = azurerm_subnet.module.id
}

resource "azurerm_storage_account" "for_func" {
  name                     = format("st%s%s", join("", split("-", var.identifier)), local.storage_suffix)
  location                 = data.azurerm_resource_group.main.location
  resource_group_name      = data.azurerm_resource_group.main.name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_network_rules" "for_func" {
  resource_group_name  = data.azurerm_resource_group.main.name
  storage_account_name = azurerm_storage_account.for_func.name

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.module.id]
}

#------------------------------------------------------------------------------
# This storage exists just for file temporarily because VNet integration does not support the drive mount feature currently.
# See https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#restrict-your-storage-account-to-a-virtual-network-preview
#------------------------------------------------------------------------------
resource "azurerm_storage_account" "for_fileshare" {
  name                     = format("st%s%s%s", join("", split("-", var.identifier)), local.storage_suffix, "fs")
  location                 = data.azurerm_resource_group.main.location
  resource_group_name      = data.azurerm_resource_group.main.name
  account_kind             = "Storagev2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
