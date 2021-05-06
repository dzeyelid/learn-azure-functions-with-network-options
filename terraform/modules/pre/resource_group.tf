resource "azurerm_resource_group" "main" {
  name     = "rg-${local.identifier_in_module}"
  location = var.location
}
