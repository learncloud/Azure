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


## 네트워크 인터페이스 생성
resource "azurerm_network_interface" "li_nic" {
    count = var.node_count
    name = "${var.resource_prefix}-${format("%04d",count.index)}-NIC" // ${format()} 형식은 숫자(count)를 10진수로 변경한다는 뜻  ,count.index는 상수 증가 1씩 증가 한다는 의미
    location = var.node_location
    resource_group_name = azurerm_resource_group.li_rg.name
    ip_configuration { //private IP 정의
        name = "internal"
        subnet_id = azurerm_subnet.li_sub.id
        private_ip_address_allocation = "Dynamic"
    }
}

# ## NIC에 NSG적용 // Nic 개수가 다수일경우 어떤 nic에 nsg를 적용해야하는지 모르기때문에 에러가 남, 즉 nic에 nsg를 붙이고 싶으면 nic를 1개만 만들던지해야함
# resource "azurerm_network_interface_security_group_association" "li_nic_nsg_association" {
#   network_interface_id      = azurerm_network_interface.li_nic.id
#   network_security_group_id = azurerm_network_security_group.li_nsg.id
# }



