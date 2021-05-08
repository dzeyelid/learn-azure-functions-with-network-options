# Examples to learn various network options of Azure Functions

This repository includes examples below.

- Using Service Endpoint
- Using Private Endpoint

These examples can be deployed by Terraform.

## Azure Functions with Service Endpoint

Using Service Endpoint and virtual network restriction is an easy way to secure your routing from Azure Functions to Azure resources such as Storage Account.

See [README](/terraform/examples/service_endpoint/README.md) for details.

## Azure Functions with Private Endpint

Using Private Endpoint, you can route privately inside a virtual network.

When deploying the example environment, Terraform needs to be able to access the File share of the Storage Account in the private virtual network. So this repository also provides the environment to run Terraform in a virtual network that peers to the example's network.

See [README](/terraform/examples/private_endpoint/README.md) for details.
