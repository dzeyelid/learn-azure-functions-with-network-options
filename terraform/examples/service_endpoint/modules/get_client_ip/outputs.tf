output "client_ip" {
  value = jsondecode(data.http.get_client_ip.body).ip
}
