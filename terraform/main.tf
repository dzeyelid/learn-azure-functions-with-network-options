# Create an environment to run Terraform
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

module "pre" {
  source = "./modules/pre"

  identifier = var.identifier
  location   = var.location
}
