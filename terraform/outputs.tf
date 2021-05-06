output "terraform_runner" {
  value = {
    resource_group_name  = module.pre.resource_group_name
    virtual_network_name = module.pre.virtual_network_name
    state = {
      storage_account = module.pre.storage_account
    }
  }
}

output "terraform_state_storage_account_access_key" {
  value     = module.pre.storage_account_access_key
  sensitive = true
}
