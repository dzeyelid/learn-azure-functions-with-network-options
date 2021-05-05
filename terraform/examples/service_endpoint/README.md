# Deployment

Move to terraform project directory and initialize it.

```bash
cd terraform
terraform init
```

Next, create `.auto.tfvars` with the following content. About `modules`, you need to include module names that you want to deploy.

```hcl
location = "japaneast"
identifier = "awesome-example"
modules = [
#  "storage_as_service_endpoint",
]
```

Then, run `plan` and `apply`.

```bash
terraform plan
terraform apply
```

After a while, the result would be shown.

```
Apply complete! Resources: 79 added, 0 changed, 0 destroyed.

Outputs:

storage_as_service_endpoint_function_url_check = "https://func-<your identifier>-storage-as-se.azurewebsites.net/api/check"
```

Try to open the check URLs. They would return an IP address that is assigned to the target host.

To destroy the resources, run `destroy` command.

```bash
terraform destroy
```