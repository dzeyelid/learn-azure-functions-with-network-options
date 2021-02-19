output "get_function_package_url_result" {
  value      = module.get_function_package_url.func.download_url
  depends_on = [module.get_function_package_url]
}

output "service_endpoint_function_url_check" {
  value = try(module.service_endpoint["function_url_check"], "Not used")
}

output "service_endpoint_west_eu_function_url_check" {
  value = try(module.service_endpoint_west_eu["function_url_check"], "Not used")
}

output "private_endpoint_function_url_check" {
  value = try(module.private_endpoint["function_url_check"], "Not used")
}

output "access_via_private_endpoint_function_url_check" {
  value = try(module.access_via_private_endpoint["function_url_check"], "Not used")
}
