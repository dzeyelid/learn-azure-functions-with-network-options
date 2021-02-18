locals {
  private_storage_blob_dns_zone_name = "privatelink.blob.core.windows.net"
}

resource "azurerm_storage_account" "for_func" {
  name                     = format("st%s", join("", split("-", local.identifier_in_module)))
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

#------------------------------------------------------------------------------
# This storage exists just for file temporarily because VNet integration does not support the drive mount feature currently.
# See https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#restrict-your-storage-account-to-a-virtual-network-preview
#------------------------------------------------------------------------------
resource "azurerm_storage_account" "for_fileshare" {
  name                     = format("st%s%s", join("", split("-", local.identifier_in_module)), "fs")
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_kind             = "StorageV2"
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
