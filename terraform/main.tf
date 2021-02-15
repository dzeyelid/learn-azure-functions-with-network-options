terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.42"
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

output "get_function_package_url_result" {
  value = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "service_endpoint" {
  for_each = toset(try([element(var.modules, index(var.modules, "service_endpoint"))], []))

  source = "./modules/service_endpoint"

  identifier           = "${var.identifier}-se"
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "service_endpoint_west_eu" {
  for_each = toset(try([element(var.modules, index(var.modules, "service_endpoint_west_eu"))], []))

  source = "./modules/service_endpoint_west_eu"

  identifier           = "${var.identifier}-sewe"
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "private_endpoint" {
  for_each = toset(try([element(var.modules, index(var.modules, "private_endpoint"))], []))

  source = "./modules/private_endpoint"

  identifier           = "${var.identifier}-pe"
  location             = var.location
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "access_via_private_endpoint" {
  for_each = toset(try([element(var.modules, index(var.modules, "access_via_private_endpoint"))], []))

  source = "./modules/access_via_private_endpoint"

  identifier           = var.identifier
  location             = var.location
  function_package_url = var.access_via_private_endpoint_function_package_url
  vm_admin_username    = var.vm_admin_username
  vm_admin_password    = var.vm_admin_password
}
