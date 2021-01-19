locals {
  module_name                        = "private-endpoint"
  subnet_name                        = "snet-${var.identifier}-${local.module_name}"
  app_plan_name                      = "plan-${var.identifier}-${local.module_name}"
  function_name                      = "func-${var.identifier}-${local.module_name}"
  vnet_address_space                 = "10.0.0.0/16"
  storage_suffix                     = "pe"
  private_storage_blob_dns_zone_name = "privatelink.blob.core.windows.net"
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

resource "azurerm_subnet" "for_func" {
  name                 = "${local.subnet_name}-for-func"
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

resource "azurerm_subnet" "for_private_endpoint" {
  name                                           = "${local.subnet_name}-for-private-endpoint"
  resource_group_name                            = azurerm_resource_group.main.name
  virtual_network_name                           = azurerm_virtual_network.main.name
  address_prefixes                               = [cidrsubnet(azurerm_virtual_network.main.address_space[0], 8, 1)]
  enforce_private_link_endpoint_network_policies = true
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
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.for_fileshare.primary_connection_string
    WEBSITE_CONTENTSHARE                     = local.function_name
    FUNCTIONS_WORKER_RUNTIME                 = "dotnet"
    WEBSITE_VNET_ROUTE_ALL                   = 1
    WEBSITE_DNS_SERVER                       = "168.63.129.16"
    WEBSITE_RUN_FROM_PACKAGE                 = var.function_package_url
    StorageBlobHost                          = azurerm_storage_account.for_func.primary_blob_host
  }

  depends_on = [
    azurerm_private_endpoint.for_func_blob,
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
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

#------------------------------------------------------------------------------
# This storage exists just for file temporarily because VNet integration does not support the drive mount feature currently.
# See https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#restrict-your-storage-account-to-a-virtual-network-preview
#------------------------------------------------------------------------------
resource "azurerm_storage_account" "for_fileshare" {
  name                     = format("st%s%s%s", join("", split("-", var.identifier)), local.storage_suffix, "fs")
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_kind             = "Storagev2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#------------------------------------------------------------------------------
# Azure DNS Private Zone
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "for_func_blob" {
  name                = local.private_storage_blob_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

#------------------------------------------------------------------------------
# Private endpoint
#------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "for_func_blob" {
  name                = "${azurerm_storage_account.for_func.name}-blob-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.for_private_endpoint.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.for_func_blob.id]
  }

  private_service_connection {
    name                           = "StorageBlobPrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.for_func.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "for_func_blob" {
  name                  = "for-func-blob-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func_blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
