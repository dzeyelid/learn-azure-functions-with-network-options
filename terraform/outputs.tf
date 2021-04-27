# output "get_function_package_url_result" {
#   value      = module.get_function_package_url.func.download_url
#   depends_on = [module.get_function_package_url]
# }

output "storage_as_service_endpoint_function_url_check" {
  value = try(module.storage_as_service_endpoint["selected"].function_url_check, "Not used")
}

output "storage_via_private_endpoint_function_url_check" {
  value = try(module.storage_via_private_endpoint["selected"].function_url_check, "Not used")
}

output "access_cosmosdb_via_private_endpoint_function_url_check" {
  value = try(module.access_cosmosdb_via_private_endpoint["selected"].function_url_check, "Not used")
}

output "access_func_via_private_endpoint_function_url_check" {
  value = try(module.access_func_via_private_endpoint["selected"].function_url_check, "Not used")
}
