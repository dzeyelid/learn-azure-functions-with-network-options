terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.3.0"
    }
  }
}

locals {
  repository = "learn-azure-functions-with-network-options"
  owner      = "dzeyelid"
}

data "github_release" "latest" {
  repository  = local.repository
  owner       = local.owner
  retrieve_by = "latest"
}

data "http" "get_assets" {
  url = data.github_release.latest.asserts_url

  request_headers = {
    Accept = "application/vnd.github.v3+json"
  }
}
