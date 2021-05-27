resource "azurerm_network_profile" "main" {
  name                = "${local.identifier_in_module}-network-profile"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  container_network_interface {
    name = "terraform-runner"

    ip_configuration {
      name      = "ipconfig"
      subnet_id = azurerm_subnet.ci.id
    }
  }
}

resource "azurerm_container_group" "main" {
  name                = "ci-${local.identifier_in_module}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Private"
  network_profile_id  = azurerm_network_profile.main.id
  os_type             = "Linux"

  container {
    name   = "terraform-runner"
    image  = "ghcr.io/dzeyelid/terraform-runner:latest"
    cpu    = "1"
    memory = "1.5"

    # Dummy (it required at least one)
    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  # identity {
  #   type = "SystemAssigned"
  # }
}
