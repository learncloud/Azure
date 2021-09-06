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

## 로드밸런서 생성
resource "azurerm_lb" "li_lb" {
    resource_group_name = azurerm_resource_group.li_rg.name
    name = "li-lb"
    location = var.node_location
    sku = "standard"
    frontend_ip_configuration { //로드밸런서 프론트 엔드 이름, 주소 명시
        name = "front-ip"
        public_ip_address_id = azurerm_public_ip.li_pip.id
    }
}
## 로드밸런서 백엔드풀 생성
resource "azurerm_lb_backend_address_pool" "li_back" { //로드밸런서 백 엔드 이름, 어느 로드벨런서 백엔드인지를 명시
    resource_group_name = azurerm_resource_group.li_rg.name
    loadbalancer_id = azurerm_lb.li_lb.id
    name = "li-back"
}
## 백엔드풀에 가상머신 붙이기
resource "azurerm_network_interface_backend_address_pool_association" "li_backPooL" { //
    count = var.node_count
    backend_address_pool_id = azurerm_lb_backend_address_pool.li_back.id
    ip_configuration_name = "internal"
    network_interface_id = element(azurerm_network_interface.li_nic.*.id, count.index)
}
## 로드밸런서 nat 룰 생성
resource "azurerm_lb_nat_rule" "li_nat_rule" {
    //Inbound nat rule 숫자와 vm connect 숫자가 일치하지 않아도 문제없이 생성이됨
    count = var.node_count
    resource_group_name = azurerm_resource_group.li_rg.name
    loadbalancer_id = azurerm_lb.li_lb.id
    name = "${var.resource_prefix}-${format("%02d",count.index)}"
    protocol = "tcp"
    frontend_port = "3${format("%04d",count.index)}" // format("%04d",count.index+1) -> +1은 지정된 카운트 범위내에서 랜덤으로 상수가 생성됩니다
    backend_port = 22
    frontend_ip_configuration_name = "front-ip"
}
## nat룰에 네트워크인터페이스, 가상머신 붙이기
resource "azurerm_network_interface_nat_rule_association" "li_natrule_association" {
    count = var.node_count
    network_interface_id = element(azurerm_network_interface.li_nic.*.id, count.index)
    ip_configuration_name = "internal"
    nat_rule_id = element(azurerm_lb_nat_rule.li_nat_rule.*.id, count.index)
    
}

##A resource with the ID "/subscriptions/801d5b45-4c84-4353-a1ce-213384a016aa/resourceGroups/linuxnode-RG/providers/Microsoft.Network/publicIPAddresses/LB-Pip" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_public_ip" for more information.
##커스텀 이미지로 VM 생성하기