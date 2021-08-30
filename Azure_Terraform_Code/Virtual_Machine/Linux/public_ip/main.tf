# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.71.0"
      
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}


resource "azurerm_resource_group" "li_rg" {
    name = "${var.resource_prefix}-RG" 
    location = var.node_location
}

## public IP Standard를 만들려면, Dynamic으로 만들수없습니다. Global 문제로 생성이 안되고 Regional로 됩니다.
resource "azurerm_public_ip" "li_pip" {
    name = "${var.resource_prefix}-Pip"
    resource_group_name = azurerm_resource_group.li_rg.name
    location = var.node_location
    allocation_method = "Static"
    sku = "standard"
    sku_tier = "Regional"
    availability_zone = "No-Zone"
}

resource "azurerm_virtual_network" "li_vnet" {
    name = "${var.resource_prefix}-vnet"
    resource_group_name = azurerm_resource_group.li_rg.name
    location = var.node_location
    address_space = var.node_address_space
}
