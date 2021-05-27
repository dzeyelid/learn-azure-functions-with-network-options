terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  asset_names = {
    func = "functions.zip"
  }
}

module "get_function_package_url" {
  for_each = local.asset_names
  source   = "./modules/get_function_package_url"

  asset_name = each.value
}

module "get_client_ip" {
  source = "./modules/get_client_ip"
}

module "storage_as_service_endpoint" {
  for_each = toset(0 <= try(index(var.modules, "storage_as_service_endpoint"), -1) ? ["selected"] : [])

  source = "./modules/storage_as_service_endpoint"

  identifier           = var.identifier
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url
  client_ip            = module.get_client_ip.client_ip

  depends_on = [
    module.get_function_package_url
  ]
}

module "storage_as_service_endpoint_private_route" {
  for_each = toset(0 <= try(index(var.modules, "storage_as_service_endpoint_private_route"), -1) ? ["selected"] : [])

  source = "./modules/storage_as_service_endpoint_private_route"

  identifier           = var.identifier
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}
