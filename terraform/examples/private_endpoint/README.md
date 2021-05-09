# Azure Functions access to Storage account via Private Endpint

Using Private Endpoint, you can route privately inside a virtual network.

![Azure Function access to Storage account via Private Endpoint](../../../docs/images/access-via-private-endpoint_001.png)

When deploying the example environment, Terraform needs to be able to access the File share of the Storage Account in the private virtual network. So this repository also provides the environment to run Terraform in a virtual network that peers to the example's network.

![Local client outside of the virtual network can't reach the File share, so Terraform should be run within the network.](../../../docs/images/access-via-private-endpoint_002.png)

## Deployment

### Prepare

First, we should deploy the environment to run the Terraform within a virtual network on Azure.

```powershell
cd terraform

terraform init
terraform plan
terraform apply
```

Then, using the output values configure the backend config.

Powershell

```powershell
$output = (terraform output -json | ConvertFrom-Json)

$PROJECT_PATH = "examples/private_endpoint"
$BACKEND_CONFIG = "$PROJECT_PATH/backend.tfvars"

echo "storage_account_name = ""$($output.terraform_runner.value.state.storage_account.name)""" >> $BACKEND_CONFIG
echo "container_name = ""$($output.terraform_runner.value.state.storage_account.container_name)""" >> $BACKEND_CONFIG
echo "key = ""terraform.tfstate""" >> $BACKEND_CONFIG
echo "access_key = ""$($output.terraform_state_storage_account_access_key.value)""" >> $BACKEND_CONFIG

# Show the resource group name and virtual network name of the environment to run Terraform for the following step
echo $output.terraform_runner.value.resource_group_name
echo $output.terraform_runner.value.virtual_network_name
```

Bash

```bash
PROJECT_PATH="examples/private_endpoint"
BACKEND_CONFIG="$PROJECT_PATH/backend.tfvars"

echo "storage_account_name = \"$(terraform output -json | jq -r '.terraform_runner.value.state.storage_account.name')\"" >> $BACKEND_CONFIG
echo "container_name = \"$(terraform output -json | jq -r '.terraform_runner.value.state.storage_account.container_name')\"" >> $BACKEND_CONFIG
echo "key = \"terraform.tfstate\"" >> $BACKEND_CONFIG
echo "access_key = \"$(terraform output -json | jq -r '.terraform_state_storage_account_access_key.value')\"" >> $BACKEND_CONFIG

# Show the resource group name and virtual network name of the environment to run Terraform for the following step
terraform output -json | jq -r '.terraform_runner.value.resource_group_name'
terraform output -json | jq -r '.terraform_runner.value.virtual_network_name'
```

And move to the example directory and initialize it. If you already run `init` before, you should set an option `-reconfigure` due to that backend is changed by the preparing.

```bash
cd $PROJECT_PATH
terraform init -backend-config="backend.tfvars"
```

Next, create `.auto.tfvars` by copying `.auto.tfvars.example` and edit them along your environment. About `modules`, you need to include module names that you want to deploy.

- `terraform.virtual_network_name`'s value is `terraform_runner.value.virtual_network_name` of output above.
- `terraform.resource_group_name`'s value is `terraform_runner.value.resource_group_name` of output above.

```hcl
location = "japaneast"
identifier = "<identifier>"

terraform = {
  virtual_network_name = "vnet-<identifier>-terraform-runner"
  resource_group_name = "rg-<identifier>-terraform-runner"
}

modules = [
  "storage_via_private_endpoint",
  # "access_cosmosdb_via_private_endpoint",
  # "access_func_via_private_endpoint",
]

# When you deploy `access_func_via_private_endpoint` module, you need set user name and password for Virtual Machine like below.
# vm_admin_username = "<VM's admin username>"
# vm_admin_password = "<VM's admin password>"
```

Then, run `plan` and `apply`.

```bash
terraform plan
terraform apply
```

After a while, the result would be shown.

```
Apply complete! Resources: 20 added, 0 changed, 0 destroyed.

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

To update them, you should run Terraform in the deployed ACI instead of your local client. Otherwise, you will get the following error below.

```bash
docker login azure
docker context create aci acicontext

# Select the subscription and the resource group of the environment that run Terraform

docker context use acicontext

# Confirm the deployed ACI's container ID
docker ps

# Execute bash in the container
docker exec -it <ACI container ID> /bin/bash
```

In the container, sign in to Azure and copy the `backend.tfvars` and `.auto.tfvars` onto the container, then you can run Terraform command. The container already includes the same code, but you can get necessary code using `git` if you prefer.

```bash
az login --use-device-code

cd terraform/examples/private_endpoint
vi backend.tfvars
vi .auto.tfvars

terraform init -backend-config="backend.tfvars"
terraform plan
```

This is an error occurred when run next terraform command from your local client.

```
Error: shares.Client#GetProperties: Failure responding to request: StatusCode=403 -- Original Error: autorest/azure: Service returned an error. Status=403 Code="AuthorizationFailure" Message="This request is not authorized to perform this operation.\nRequestId:00000000-0000-0000-0000-000000000000\nTime:2021-05-09T14:52:15.5600946Z"
```

To destroy the resources, run `destroy` command.

```bash
terraform destroy
```