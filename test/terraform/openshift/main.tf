provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  random_name = "${var.resource_prefix}${random_id.suffix.dec}"
}

resource "azurerm_resource_group" "test" {
  name     = local.random_name
  location = var.region
}
resource "azurerm_virtual_network" "test" {
  name                = local.random_name
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  address_space       = ["10.0.0.0/22"]
}

resource "azurerm_subnet" "master-subnet" {
  name                 = "master-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.0.0/23"]
  enforce_private_link_service_network_policies = true
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

resource "azurerm_subnet" "worker-subnet" {
  name                 = "worker-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/23"]
  service_endpoints = ["Microsoft.ContainerRegistry"]
}

resource "null_resource" "aro" {
  triggers = {
    vnet = azurerm_virtual_network.test.id
    master_subnet = azurerm_subnet.master-subnet.id
    worker_subnet = azurerm_subnet.worker-subnet.id
  }

  # This is a horrible hack until terraform Azure provider officially supports this resource
  # https://github.com/terraform-providers/terraform-provider-azurerm/issues/3614.
  provisioner "local-exec" {
    command = "./create-aro-cluster.sh ${azurerm_resource_group.test.name} ${local.random_name} ${azurerm_virtual_network.test.name}"
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue
    command    = "az aro delete --resource-group ${azurerm_resource_group.test.name} --name ${local.random_name} --yes"
  }
}