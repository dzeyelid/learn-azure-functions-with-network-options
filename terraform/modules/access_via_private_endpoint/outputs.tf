output "function_url_check" {
  value = "https://${azurerm_function_app.main.default_hostname}/api/check"
}
