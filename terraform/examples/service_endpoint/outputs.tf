output "storage_as_service_endpoint_function_url_check" {
  value = try(module.storage_as_service_endpoint["selected"].function_url_check, "Not used")
}

output "storage_as_service_endpoint_private_route_function_url_check" {
  value = try(module.storage_as_service_endpoint_private_route["selected"].function_url_check, "Not used")
}
