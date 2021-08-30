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

##리소스 그룹 생성
resource "azurerm_resource_group" "li_rg" {
    name = "${var.resource_prefix}-RG"
    location = var.node_location
}

## Vnet 생성
resource "azurerm_virtual_network" "li_vnet" {
    name = "${var.resource_prefix}-vnet"
    resource_group_name = azurerm_resource_group.li_rg.name
    location = var.node_location
    address_space = var.node_address_space
}

## 서브넷 생성
resource "azurerm_subnet" "li_sub" {
    name = "${var.resource_prefix}-subnet"
    resource_group_name = azurerm_resource_group.li_rg.name
    virtual_network_name = azurerm_virtual_network.li_vnet.name
    address_prefix = var.node_address_prefix
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
## 22, 80 NSG 생성
resource "azurerm_network_security_group" "li_nsg" {
    name = "${var.resource_prefix}-nsg"
    location = var.node_location
    resource_group_name = azurerm_resource_group.li_rg.name
    security_rule {
        name = "ssh_allow"
        priority = 100
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "http_allow"
        priority = 110
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

}
## Subnet에 NSG적용
resource "azurerm_subnet_network_security_group_association" "li_subnet_nsg_association" {
    subnet_id = azurerm_subnet.li_sub.id
    network_security_group_id = azurerm_network_security_group.li_nsg.id
}

# ## NIC에 NSG적용 // Nic 개수가 다수일경우 어떤 nic에 nsg를 적용해야하는지 모르기때문에 에러가 남, 즉 nic에 nsg를 붙이고 싶으면 nic를 1개만 만들던지해야함
# resource "azurerm_network_interface_security_group_association" "li_nic_nsg_association" {
#   network_interface_id      = azurerm_network_interface.li_nic.id
#   network_security_group_id = azurerm_network_security_group.li_nsg.id
# }



## 가상머신 생성
resource "azurerm_virtual_machine" "li-vm" {
    count = var.node_count
    name = "${var.resource_prefix}-${format("%04d",count.index)}" 
    location = var.node_location
    resource_group_name = azurerm_resource_group.li_rg.name
    network_interface_ids = [element(azurerm_network_interface.li_nic.*.id, count.index)]
    vm_size = "Standard_B1s"
    delete_os_disk_on_termination = true
    storage_image_reference {
        id = var.vhd_uri
    }
    
    storage_os_disk{
        name = "lidisk-${count.index}"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    os_profile{
        # count = var.node_count // 카운트 변수 사용 불가
        computer_name = "${var.resource_prefix}-${format("%04d",count.index)}"
        admin_username = var.username
        admin_password = var.userpwd
    }
    //following a define아래 정의는 must vaules, os Profile이 linux인지 windows인지 반드시 정의해줘야합니다.
    os_profile_linux_config {
        disable_password_authentication = false
    }
}
## public IP Standard를 만들려면, Dynamic으로 만들수없습니다. Global 문제로 생성이 안되고 Regional로 됩니다.
resource "azurerm_public_ip" "li_pip" {
    name = "LB-Pip"
    resource_group_name = azurerm_resource_group.li_rg.name
    location = var.node_location
    allocation_method = "Static"
    sku = "standard"
    sku_tier = "Regional"
    availability_zone = "No-Zone"
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
    count = var.node_counts //Inbount NAT만 5대 생성함
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


##커스텀 이미지로 VM 생성하기
