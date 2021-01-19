# Deployment

```bash
cd terraform
terraform init
terraform plan
```

```bash
terraform apply

Apply complete! Resources: 31 added, 0 changed, 0 destroyed.

Outputs:

private_endpoint_function_url_check = "https://func-<your-identifier>-pe-private-endpoint.azurewebsites.net/api/check"
service_endpoint_function_url_check = "https://func-<your-identifier>-se-service-endpoint.azurewebsites.net/api/check"
service_endpoint_west_eu_function_url_check = "https://func-<your-identifier>-sewe-service-endpoint.azurewebsites.net/api/check"
```

If the URL of the private endpoint returns a global IP, wait for a while and try again.

If the URL of the service endpoint in West Europe returns an error message below, wait for a while and try again.

```
Function host is not running.
```

```bash
terraform destroy
```