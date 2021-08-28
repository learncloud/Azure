/* docs에 없는 목록*/
// LB 백엔드는 ip주소만 하드코딩가능함 (nic구성은 docs에 없음, github에서 찾아야할듯)


/* 하드코딩을 var로 숨겨야할 목록*/

// 현재는 nsg, lb백엔드, vnet, subnet 하드코딩 -> lecture4에 demo.auto.tfvars 파일에 힌트

// Premium_Verizon의 cdnpoint는 코드로 만들수없음
provider "azurerm" {
    version = "~>2.0"
    features {}
}

resource "azurerm_resource_group" "RG" {
  name     = var.resourcename
  location = var.location
  tags     = var.tags
}


resource "azurerm_storage_account" "storage" {
  name                     = var.storagename
  resource_group_name      = azurerm_resource_group.RG.name
  location                 = azurerm_resource_group.RG.location
  account_tier             = "Premium" //Premium만 가능
  account_replication_type = "LRS" //LRS, ZRS만 가능함
  account_kind             = "FileStorage"

  tags = var.tags
}

resource "azurerm_network_security_group" "nsgrule" {
  name                = "vmnsg"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location

 security_rule {
        name                       = "Http"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    //멀티 nsg
    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_network" "Tvnet" {
  name                = "v-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  #dns_servers         = ["10.0.0.4", "10.0.0.5"]
}

resource "azurerm_subnet" "subnet1" {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
    resource_group_name  = azurerm_resource_group.RG.name
    virtual_network_name = azurerm_virtual_network.Tvnet.name
  }




resource "azurerm_public_ip" "vmpip" {
    name                         = "vmpip"
    location                     = azurerm_resource_group.RG.location
    resource_group_name          = azurerm_resource_group.RG.name
    allocation_method            = "Static"
    sku                          = "Standard"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "Tnic" {
  name                = "example-nic"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Static" //Static 변경해줘야할듯
    public_ip_address_id          = azurerm_public_ip.vmpip.id
  }
}

resource "azurerm_network_interface_security_group_association" "connnsg" {
  network_interface_id      = azurerm_network_interface.Tnic.id
  network_security_group_id = azurerm_network_security_group.nsgrule.id
}



#Create window VM 
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  size                = "Standard_F2"
  admin_username      = "jjh"
  admin_password      = "wjdwogjs1!!!"

  network_interface_ids = [
    azurerm_network_interface.Tnic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
 
 resource "azurerm_public_ip" "Tlbip" {
   name                = "PublicIPForLB"
   location            = azurerm_resource_group.RG.location
   resource_group_name = azurerm_resource_group.RG.name
   allocation_method   = "Static"
   sku                 = "Standard"
 }

 resource "azurerm_lb" "TLB" {
   name                = "TestLoadBalancer"
   location            = azurerm_resource_group.RG.location
   resource_group_name = azurerm_resource_group.RG.name
   sku                          = "Standard"
   

   frontend_ip_configuration {
     name                 = "PublicIPAddress"
     public_ip_address_id = azurerm_public_ip.Tlbip.id
   }
 }


 resource "azurerm_lb_backend_address_pool" "Tlbback" {
  resource_group_name = azurerm_resource_group.RG.name
  loadbalancer_id     = azurerm_lb.TLB.id
  name                = "BackEndAddressPool"
 
 }

  resource "azurerm_lb_backend_address_pool_address" "backaddr" {
  name                    = "backaddr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.Tlbback.id
  virtual_network_id      = azurerm_virtual_network.Tvnet.id
  ip_address              = "10.0.0.5"
}


 resource "azurerm_lb_rule" "Tlbrule" {
   resource_group_name            = azurerm_resource_group.RG.name
   loadbalancer_id                = azurerm_lb.TLB.id
   name                           = "LBRule"
   protocol                       = "Tcp"
   frontend_port                  = "80"
   backend_port                   = "80"
   frontend_ip_configuration_name = "PublicIPAddress"
   backend_address_pool_id        = azurerm_lb_backend_address_pool.Tlbback.id
   probe_id                       = azurerm_lb_probe.lbprobe.id
 }

 resource "azurerm_lb_probe" "lbprobe" {
   resource_group_name = azurerm_resource_group.RG.name
   loadbalancer_id     = azurerm_lb.TLB.id
   name                = "http-running-probe"
   port                = "80"
 }


resource "azurerm_cdn_profile" "cdnprofile" {
  name                = "cdnprofile"
  location            = "Southeast Asia"
  resource_group_name = azurerm_resource_group.RG.name
  sku                 = "Premium_Verizon"
}




# resource "azurerm_virtual_machine" "Tlinuxvm" {
#   name                  = "${var.prefix}-vm"
#   location              = azurerm_resource_group.RG.location
#   resource_group_name   = azurerm_resource_group.RG.name
#   network_interface_ids = [azurerm_network_interface.Tnic.id]
#   vm_size               = "Standard_DS1_v2"

#   # Uncomment this line to delete the OS disk automatically when deleting the VM
#   # delete_os_disk_on_termination = true

#   # Uncomment this line to delete the data disks automatically when deleting the VM
#   # delete_data_disks_on_termination = true

#   storage_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }
#   storage_os_disk {
#     name              = "myosdisk1"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     managed_disk_type = "Standard_LRS"
#   }
#   os_profile {
#     computer_name  = "hostname"
#     admin_username = "${var.idd}"
#     admin_password = "${var.pass}"
#   }
#   os_profile_linux_config {
#     disable_password_authentication = false
#   }
#   tags = {
#     environment = "staging"
#   }
# }

# resource "azurerm_network_security_group" "vmnsg" {
#     name                = "vmnsg"
#     location            = azurerm_resource_group.RG.location
#     resource_group_name = azurerm_resource_group.RG.name
    
#     security_rule {
#         name                       = "Http"
#         priority                   = 1001
#         direction                  = "Inbound"
#         access                     = "Allow"
#         protocol                   = "Tcp"
#         source_port_range          = "*"
#         destination_port_range     = "80"
#         source_address_prefix      = "*"
#         destination_address_prefix = "*"
#     }
    
#     tags = {
#         environment = "Terraform Demo"
#     }
# }

