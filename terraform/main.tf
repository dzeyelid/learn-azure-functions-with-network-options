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

output "result" {
  value = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "service_endpoint" {
  source = "./modules/service_endpoint"

  identifier           = "${var.identifier}-se"
  location             = "japaneast"
  function_package_url = module.get_function_package_url.func.download_url

  depends_on = [
    module.get_function_package_url
  ]
}

module "service_endpoint_west_eu" {
  source = "./modules/service_endpoint_west_eu"

  identifier           = "${var.identifier}-sewe"
  function_package_url = module.get_function_package_url.func.download_url
}

module "private_endpoint" {
  source = "./modules/private_endpoint"

  identifier           = "${var.identifier}-pe"
  location             = "japaneast"
  function_package_url = module.get_function_package_url.func.download_url
}
