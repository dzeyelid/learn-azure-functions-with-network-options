locals {
  cosmosdb_name = "cosmos-${local.identifier_in_module}"
  cosmosdb = {
    database_name = "item"
    throughput    = 400
    containers = {
      plans = {
        name               = "plans"
        partition_key_path = "/course/id"
      }
    }
  }
  private_cosmosdb_dns_zone_name = "privatelink.documents.azure.com"
}

resource "azurerm_cosmosdb_account" "main" {
  name                              = local.cosmosdb_name
  location                          = azurerm_resource_group.main.location
  resource_group_name               = azurerm_resource_group.main.name
  offer_type                        = "Standard"
  kind                              = "GlobalDocumentDB"
  ip_range_filter                   = "126.159.25.132,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26"
  is_virtual_network_filter_enabled = true

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  virtual_network_rule {
    id = azurerm_subnet.for_func.id
  }
}

resource "azurerm_cosmosdb_sql_database" "main" {
  name                = local.cosmosdb.database_name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = local.cosmosdb.throughput
}

resource "azurerm_cosmosdb_sql_container" "main" {
  for_each = local.cosmosdb.containers

  name                = each.value.name
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.main.name
  partition_key_path  = each.value.partition_key_path
}

#------------------------------------------------------------------------------
# Azure DNS Private Zone
#------------------------------------------------------------------------------
resource "azurerm_private_dns_zone" "for_func_cosmosdb" {
  name                = local.private_cosmosdb_dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
}

#------------------------------------------------------------------------------
# Private endpoint
#------------------------------------------------------------------------------
resource "azurerm_private_endpoint" "for_func_cosmosdb" {
  name                = "${azurerm_cosmosdb_account.main.name}-blob-private-endpoint"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.for_private_endpoint.id

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.for_func_cosmosdb.id]
  }

  private_service_connection {
    name                           = "CosmosDbPrivateLinkConnection"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["sql"]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "for_func_cosmosdb" {
  name                  = "for-func-cosmosdb-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.for_func_cosmosdb.name
  virtual_network_id    = azurerm_virtual_network.main.id
}
