# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}


resource "azurerm_resource_group""" "rg" {
    name = "{var.laberPrefix}-A05-RG"
    location = var.region

}
# Define the virtual network
resource "azurerm_virtual_network" "vnet" {
    name               = "${var.labelPrefix}-A05Vnet"
    address_space      =["10.0.0.0/16"]
    location           = azurerm_resource_group.rg.location
    resouresource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet" "" {
    name               = "${var.labelPrefix}-A05Subnet"
    address_space      =["10.0.1.0/24"]
    resouresource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
}

# Define a public IP address
resource " azurerm_public_ip" "webserver" {
    name               = "${var.labelPrefix}-A05PubicIP"
    location           = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method  = "Dynamic"
}
# Define the network security group and rules
resource "azurerm_network_security_group" "webserver" {
    name               = "${var.labelPrefix}-A05NSG"
    location           = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name                       = "HTTPS"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

#107 DEfine the network interface
resource ""azure_network_interface" "webserver" {
    name               = "${var.labelPrefix}-A05NIC"
    location           = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "{var.labelPrefix}-A05NICConfig"
        subnet_id = azurerm_subnet.webserver.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id       = azurerm_public_ip.webserver.id

           }
}
#121 Link the security group to the nic
resource "azurerm_network_interface_security_group_association" "webserver" {
    network_interface_id = azurerm_network_interface.webserver.id
    network_security_group_id = azurerm_network_security_group.webserver.id
}

#127 Define the init script template
data "cloudinit_config" "init" {
    gzip = false
    base64_encode = true
    part {
        filename = "init.sh"
        content_type = "text/x-shellscript"
        content = file("${path.module}/init.sh")
    }
}

#140 Define the virtual
resource "azurerm_linux_virtual_machine" "webserver" {
    name                = "${var.labelPrefix}-A05VM"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    size                = "Standard_B1s"
    admin_username      = "adminuser"
    network_interface_ids = [azurerm_network_interface.webserver.id]
    os_disk {
        name             = "${var.labelPrefix}-A05OSDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }
    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }
    custom_data = data.cloudinit_config.init.rendered
    computer_name = "${var.labelPrefix}-A05VM"
    admin_username = var.admin_username
    disable_password_authentication = true

    admin_ssh_key {
        username = var.admin_username
        public_key = file(~/.ssh/id_rsa.pub)
    }

    custom_data = data.cloudinit_config.init.rendered
}
