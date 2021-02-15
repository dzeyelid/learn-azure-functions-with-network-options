# output "service_endpoint_function_url_check" {
#   value = 0 <= try(index(var.modules, "service_endpoint"), -1) ? tostring(module.service_endpoint.function_url_check) : "Not used"
# }

# output "service_endpoint_west_eu_function_url_check" {
#   value = 0 <= try(index(var.modules, "service_endpoint_west_eu"), -1) ? tostring(module.service_endpoint_west_eu.function_url_check) : "Not used"
# }

# output "private_endpoint_function_url_check" {
#   value = 0 <= try(index(var.modules, "private_endpoint"), -1) ? tostring(module.private_endpoint.function_url_check) : "Not used"
# }
