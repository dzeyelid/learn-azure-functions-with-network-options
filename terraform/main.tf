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

module "service_endpint" {
  source = "./modules/service_endpoint"

  identifier = "${var.identifier}-se"
  location   = "japaneast"
}

module "service_endpint_west_eu" {
  source = "./modules/service_endpoint_west_eu"

  identifier = "${var.identifier}-sewe"
}
