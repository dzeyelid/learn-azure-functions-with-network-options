# Deployment

```powershell
cd terraform

$PROJECT_PATH = "examples/private_endpoint"
$BACKEND_CONFIG = "$PROJECT_PATH/backend.tfvars"
$AUTO_TFVARS = "$PROJECT_PATH/.auto.tfvars"

terraform init
terraform plan
terraform apply

$output = (terraform output -json | ConvertFrom-Json)

echo "storage_account_name = ""$($output.terraform_runner.value.state.storage_account.name)""" >> $BACKEND_CONFIG
echo "container_name = ""$($output.terraform_runner.value.state.storage_account.container_name)""" >> $BACKEND_CONFIG
echo "key = ""terraform.tfstate""" >> $BACKEND_CONFIG
echo "access_key = ""$($output.terraform_state_storage_account_access_key)""" >> $BACKEND_CONFIG
```

Move to terraform project directory and initialize it.

```bash
cd $PROJECT_PATH
terraform init -backend-config=backend.tfvars
```

Next, create `.auto.tfvars` with the following content. About `modules`, you need to include module names that you want to deploy.

```hcl
location = "japaneast"
identifier = "awesome-example"
modules = [
#  "storage_via_private_endpoint",
#  "access_cosmosdb_via_private_endpoint",
#  "access_func_via_private_endpoint",
]

# When you deploy `access_func_via_private_endpoint` module, you need set user name and password for Virtual Machine like below.
vm_admin_username = ""
vm_admin_password = ""
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

access_cosmosdb_via_private_endpoint_function_url_check = "https://func-<your identifier>-cosmos-via-pe.azurewebsites.net/api/check"
access_func_via_private_endpoint_function_url_check = "https://func-<your identifier>-func-via-pe.azurewebsites.net/api/check"
storage_via_private_endpoint_function_url_check = "https://func-<your identifier>-storage-via-pe.azurewebsites.net/api/check
```

Try to open the check URLs. They would return an IP address that is assigned to the target host.

- If the check URL of the private endpoint returns a global IP, wait for a while and try again. It takes a while that Internal routing works correctly.

  ```
  Function host is not running.
  ```

To destroy the resources, run `destroy` command.

```bash
terraform destroy
```