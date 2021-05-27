locals {
  module_name                        = "storage-via-pe"
  identifier_in_module               = "${var.identifier}-${local.module_name}"
  subnet_name                        = "snet-${local.identifier_in_module}"
  app_plan_name                      = "plan-${local.identifier_in_module}"
  function_name                      = "func-${local.identifier_in_module}"
  vnet_address_space                 = "10.0.0.0/16"
  storage_suffix                     = "pe"
  private_storage_blob_dns_zone_name = "privatelink.blob.core.windows.net"
  private_storage_file_dns_zone_name = "privatelink.file.core.windows.net"
}

data "azurerm_virtual_network" "terraform" {
  name                = var.terraform.virtual_network_name
  resource_group_name = var.terraform.resource_group_name
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.identifier_in_module}"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.identifier_in_module}"
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

# For terraform connection
resource "azurerm_virtual_network_peering" "example" {
  name                      = "example"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.main.name
  remote_virtual_network_id = data.azurerm_virtual_network.terraform.id
}

# For terraform connection
resource "azurerm_virtual_network_peering" "terraform" {
  name                      = "terraform"
  resource_group_name       = data.azurerm_virtual_network.terraform.resource_group_name
  virtual_network_name      = data.azurerm_virtual_network.terraform.name
  remote_virtual_network_id = azurerm_virtual_network.main.id
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
  https_only                 = true

  site_config {
    always_on     = true
    ftps_state    = "Disabled"
    http2_enabled = true
  }

  app_settings = {
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = azurerm_storage_account.for_func.primary_connection_string
    WEBSITE_CONTENTSHARE                     = local.function_name
    WEBSITE_CONTENTOVERVNET                  = 1
    FUNCTIONS_WORKER_RUNTIME                 = "dotnet"
    WEBSITE_VNET_ROUTE_ALL                   = 1
    WEBSITE_DNS_SERVER                       = "168.63.129.16"
    WEBSITE_RUN_FROM_PACKAGE                 = var.function_package_url
    TargetHost                               = azurerm_storage_account.for_func.primary_blob_host
  }

  depends_on = [
    azurerm_private_endpoint.for_func_blob,
  ]
}

resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = azurerm_function_app.main.id
  subnet_id      = azurerm_subnet.for_func.id
}

resource "random_string" "storage_for_func" {
  length  = 22
  upper   = false
  special = false
  keepers = {
    resource_group_id = azurerm_resource_group.main.id
    module            = local.identifier_in_module
  }
}

resource "azurerm_storage_account" "for_func" {
  name                     = "st${random_string.storage_for_func.result}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account_network_rules" "for_func" {
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_name = azurerm_storage_account.for_func.name

  default_action = "Deny"
}

resource "azurerm_storage_share" "for_func" {
  name                 = local.function_name
  storage_account_name = azurerm_storage_account.for_func.name
}

#------------------------------------------------------------------------------
# Azure DNS Private Zone
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "for_func_blob" {
  name                = local.private_storage_blob_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "for_func_blob" {
  name                  = "for-func-blob-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func_blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_dns_zone" "for_func_file" {
  name                = local.private_storage_file_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "for_func_file" {
  name                  = "for-func-file-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func_file.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# For terraform connection
resource "azurerm_private_dns_zone_virtual_network_link" "for_terraform" {
  name                  = "for-terraform-allow-access-to-file-share-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func_file.name
  virtual_network_id    = data.azurerm_virtual_network.terraform.id
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

resource "azurerm_private_endpoint" "for_func_file" {
  name                = "${azurerm_storage_account.for_func.name}-file-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.for_private_endpoint.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.for_func_file.id]
  }

  private_service_connection {
    name                           = "StorageFilePrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.for_func.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
}
