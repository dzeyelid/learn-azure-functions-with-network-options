resource "random_string" "storage_for_terraform_state" {
  length  = 22
  upper   = false
  special = false
  keepers = {
    resource_group_id = azurerm_resource_group.main.id
    module            = local.identifier_in_module
  }
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = "st${random_string.storage_for_terraform_state.result}"
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

# resource "azurerm_role_definition" "storage_for_terraform_state" {
#   name        = "storage-for-terraform-state"
#   scope       = azurerm_storage_account.terraform_state.id
#   description = "Custom role to use Storage Account to manage to terraform state"

#   permissions {
#     actions = ["Microsoft.Storage/storageAccounts/*"]
#   }

#   assignable_scopes = [
#     azurerm_storage_account.terraform_state.id,
#   ]
# }

# resource "azurerm_role_assignment" "storage_for_terraform_state" {
#   name               = uuid()
#   scope              = azurerm_storage_account.terraform_state.id
#   role_definition_id = azurerm_role_definition.storage_for_terraform_state.id
#   principal_id       = azurerm_container_group.main.identity[0].principal_id
# }
