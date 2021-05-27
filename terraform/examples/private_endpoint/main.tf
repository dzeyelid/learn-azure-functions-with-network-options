terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0.0"
    }
  }

  backend "azurerm" {}
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

module "storage_via_private_endpoint" {
  for_each = toset(0 <= try(index(var.modules, "storage_via_private_endpoint"), -1) ? ["selected"] : [])

  source = "./modules/storage_via_private_endpoint"

  identifier           = var.identifier
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url
  terraform = {
    virtual_network_name = var.terraform.virtual_network_name
    resource_group_name  = var.terraform.resource_group_name
  }

  depends_on = [
    module.get_function_package_url
  ]
}

module "access_cosmosdb_via_private_endpoint" {
  for_each = toset(0 <= try(index(var.modules, "access_cosmosdb_via_private_endpoint"), -1) ? ["selected"] : [])

  source = "./modules/access_cosmosdb_via_private_endpoint"

  identifier           = var.identifier
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "access_func_via_private_endpoint" {
  for_each = toset(0 <= try(index(var.modules, "access_func_via_private_endpoint"), -1) ? ["selected"] : [])

  source = "./modules/access_func_via_private_endpoint"

  identifier           = var.identifier
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url
  vm_admin_username    = var.vm_admin_username
  vm_admin_password    = var.vm_admin_password

  depends_on = [
    module.get_function_package_url
  ]
}
