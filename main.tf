provider "azurerm" {
    subscription_id = "63624c86-fe10-49d1-b0c7-b5b0be84da6a"
    client_id = "27ed852a-f10d-41bc-951c-d12bca932c28"
    client_secret = "ORn8Q~oT-3mfQEnDnMFtQQZHrd9nbZtaJ2Cmxc.B"
    tenant_id = "7270ce39-4b64-4579-8f7f-93639d71f1ca"

    features {
      
    }
  
}
variable "prefix"{
     default ="adi-res"
}

#create resource group
resource "azurerm_resource_group" "adi-rg" {
    name     = "${var.prefix}-rg"
    location = "West Europe"
}

#create virtual network
resource "azurerm_virtual_network" "adi-vn" {
    name = "${var.prefix}-network"
    address_space = ["11.0.0.0/16"]
    location = azurerm_resource_group.adi-rg.location
    resource_group_name = azurerm_resource_group.adi-rg.name
}
#create subnet above virtual netwok
resource "azurerm_subnet" "adi-sn" {
    name = "${var.prefix}-subnet"
    resource_group_name = azurerm_resource_group.adi-rg.name
    virtual_network_name = azurerm_virtual_network.adi-vn.name
    address_prefixes = ["11.0.2.0/24"]
}

#create network interface card
resource "azurerm_network_interface" "adi-nic" {
    name = "${var.prefix}-nic"
    location = azurerm_resource_group.adi-rg.location
    resource_group_name = azurerm_resource_group.adi-rg.name
    ip_configuration {
      name = "${var.prefix}-ip"
      subnet_id = azurerm_subnet.adi-sn.id
      private_ip_address_allocation = "Dynamic"
      public_ip_address_id = azurerm_public_ip.adi-pip.id
    }
}
#create public network
resource "azurerm_public_ip" "adi-pip" {
    name = "${var.prefix}-pip"
    location = azurerm_resource_group.adi-rg.location
    resource_group_name = azurerm_resource_group.adi-rg.name
    allocation_method = "Static"
    sku = "Standard"
}
#add netork security group
resource "azurerm_network_security_group" "adi-nsg" {
    name                = "${var.prefix}-nsg"
    location            = azurerm_resource_group.adi-rg.location
    resource_group_name = azurerm_resource_group.adi-rg.name
    security_rule {
        name                       = "Allow_rdp"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range = "3389"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    }
#associate your subnet or network interface

resource "azurerm_network_interface_security_group_association" "adi-nsg-association" {
    network_interface_id = azurerm_network_interface.adi-nic.id
    network_security_group_id = azurerm_network_security_group.adi-nsg.id
}
#create virtual machine
resource "azurerm_virtual_machine" "adi-vm" {
    name = "${var.prefix}-vm"
    location = azurerm_resource_group.adi-rg.location
    resource_group_name = azurerm_resource_group.adi-rg.name
    network_interface_ids = [azurerm_network_interface.adi-nic.id]
    vm_size = "Standard_DS1_V2"
   
    storage_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer = "WindowsServer"
        sku = "2019-Datacenter"
        version = "latest"
    }
      storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
   os_profile {
    computer_name  = "${var.prefix}-vm"
    admin_username = "adminuser"
    admin_password = "Admin@1234"
    }
     os_profile_windows_config {
        provision_vm_agent = true
        enable_automatic_upgrades = true
    }

    tags = {
        environment = "testing"
    }
}

