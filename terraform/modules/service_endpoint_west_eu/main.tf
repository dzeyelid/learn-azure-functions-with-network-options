locals {
  module_name          = "service-endpoint"
  virtual_network_name = "vnet-${var.identifier}-${local.module_name}"
  subnet_name          = "snet-${var.identifier}-${local.module_name}"
  app_plan_name        = "plan-${var.identifier}-${local.module_name}"
  function_name        = "func-${var.identifier}-${local.module_name}"
  vnet_address_space   = "10.0.0.0/16"
  storage_suffix       = "se"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.identifier}"
  location = "westeurope"
}

resource "azurerm_virtual_network" "main" {
  name                = local.virtual_network_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [local.vnet_address_space]
}

resource "azurerm_subnet" "for_func" {
  name                 = local.subnet_name
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 0)]
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

resource "azurerm_app_service_plan" "main" {
  name                = local.app_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_function_app" "main" {
  name                       = local.function_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.for_func.name
  storage_account_access_key = azurerm_storage_account.for_func.primary_access_key
  version                    = "~3"

  site_config {
    always_on = true
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.for_func.primary_connection_string
    WEBSITE_CONTENTSHARE                     = local.function_name
    FUNCTIONS_WORKER_RUNTIME                 = "dotnet"
    WEBSITE_VNET_ROUTE_ALL                   = 1
    WEBSITE_CONTENTOVERVNET                  = 1
    WEBSITE_RUN_FROM_PACKAGE                 = 1
    StorageBlobHost                          = azurerm_storage_account.for_func.primary_blob_host
  }

  depends_on = [
    azurerm_storage_share.for_func
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "module" {
  app_service_id = azurerm_function_app.main.id
  subnet_id      = azurerm_subnet.for_func.id
}

resource "azurerm_storage_account" "for_func" {
  name                     = format("st%s%s", join("", split("-", var.identifier)), local.storage_suffix)
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_network_rules" "for_func" {
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = azurerm_storage_account.for_func.name

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.for_func.id]
}

resource "azurerm_storage_share" "for_func" {
  name                 = local.function_name
  storage_account_name = azurerm_storage_account.for_func.name

  acl {
    id = "for_terraform"

    access_policy {
      permissions = "rwdl"
    }
  }
}
