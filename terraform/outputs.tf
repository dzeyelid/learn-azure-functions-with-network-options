# output "get_function_package_url_result" {
#   value      = module.get_function_package_url.func.download_url
#   depends_on = [module.get_function_package_url]
# }

output "storage_as_service_endpoint_function_url_check" {
  value      = try(module.storage_as_service_endpoint.*.function_url_check, "Not used")
  depends_on = [module.storage_as_service_endpoint]
}

output "storage_as_service_endpoint_west_eu_function_url_check" {
  value      = try(module.storage_as_service_endpoint_west_eu.*.function_url_check, "Not used")
  depends_on = [module.storage_as_service_endpoint_west_eu]
}

output "storage_via_private_endpoint_function_url_check" {
  value      = try(module.storage_via_private_endpoint.*.function_url_check, "Not used")
  depends_on = [module.storage_via_private_endpoint]
}

output "access_cosmosdb_via_private_endpoint_function_url_check" {
  value      = try(module.access_cosmosdb_via_private_endpoint.*.function_url_check, "Not used")
  depends_on = [module.access_cosmosdb_via_private_endpoint]
}

output "access_func_via_private_endpoint_function_url_check" {
  value      = try(module.access_func_via_private_endpoint.*.function_url_check, "Not used")
  depends_on = [module.access_func_via_private_endpoint]
}
