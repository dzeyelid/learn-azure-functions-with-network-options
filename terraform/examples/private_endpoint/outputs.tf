output "storage_via_private_endpoint_function_url_check" {
  value = try(module.storage_via_private_endpoint["selected"].function_url_check, "Not used")
}

output "access_cosmosdb_via_private_endpoint_function_url_check" {
  value = try(module.access_cosmosdb_via_private_endpoint["selected"].function_url_check, "Not used")
}

output "access_func_via_private_endpoint_function_url_check" {
  value = try(module.access_func_via_private_endpoint["selected"].function_url_check, "Not used")
}
