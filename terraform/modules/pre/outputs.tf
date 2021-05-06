output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "virtual_network_name" {
  value = azurerm_virtual_network.main.name
}

output "storage_account" {
  value = {
    name           = azurerm_storage_account.terraform_state.name
    container_name = azurerm_storage_container.terraform_state.name
  }
}

output "storage_account_access_key" {
  value     = azurerm_storage_account.terraform_state.primary_access_key
  sensitive = true
}

output "subnet_name" {
  value = azurerm_subnet.ci.name
}

