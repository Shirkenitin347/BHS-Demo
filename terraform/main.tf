terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate23521"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
 
resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

# Create resource group
resource "azurerm_resource_group" "webServer_rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Create virtual network
resource "azurerm_virtual_network" "webServer_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.webServer_rg.location
  resource_group_name = azurerm_resource_group.webServer_rg.name
}


# Create subnet
resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.webServer_rg.name
  virtual_network_name = azurerm_virtual_network.webServer_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs

resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.webServer_rg.location
  resource_group_name = azurerm_resource_group.webServer_rg.name
  allocation_method   = "Dynamic"
  domain_name_label =  "bhs-demo"
 
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "webServer_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.webServer_rg.location
  resource_group_name = azurerm_resource_group.webServer_rg.name

   security_rule {
    name                       = "htp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
   security_rule {
    name                       = "https"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "SSH"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.webServer_rg.location
  resource_group_name = azurerm_resource_group.webServer_rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "webServer_network_interface" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.webServer_nsg.id
}



# Create storage account for boot diagnostics
  resource "azurerm_storage_account" "webServer_storage_account" {
  name                     = "bhsdemo26102022"
  location                 = azurerm_resource_group.webServer_rg.location
  resource_group_name      = azurerm_resource_group.webServer_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "webServer_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# store .pem key locally
resource "local_file" "ssh_key" {
  filename = "webServer.pem"
  content = tls_private_key.webServer_ssh.private_key_pem
}


locals {
  custom_data = <<CUSTOM_DATA
 #!/bin/bash
sudo mkdir Docker
cd Docker
sudo apt-get remove docker docker-engine docker.io -y
sudo apt-get update
sudo apt install docker.io -y
sudo snap install docker
sudo systemctl start docker
sudo systemctl enable docker
sudo apt-get install git
sudo git clone https://github.com/Shirkenitin347/DevopsDemo
sudo cd DevopsDemo/Docker
sudo chmod 666 /var/run/docker.sock
docker build -t webserver .
docker run -it --rm -d -p 80:80 --name web webserver
  CUSTOM_DATA
  }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "Webserver_vm" {
  name                  = "WebServer"
  location              = azurerm_resource_group.webServer_rg.location
  resource_group_name   = azurerm_resource_group.webServer_rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"
  
  # custom_data = base64encode("script.sh")
  # custom_data = filebase64("script.sh")
  #custom_data = base64encode(local.custom_data)

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
	
  }

 source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "WebServer"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.webServer_ssh.public_key_openssh
  }


   provisioner "remote-exec" {
   
    connection {
          # The default username for our AMI
          user = "azureuser"
          host = azurerm_linux_virtual_machine.Webserver_vm.public_ip_address
          type     = "ssh"
          private_key = tls_private_key.webServer_ssh.private_key_pem
        }
        inline = [
			"sudo apt-get update",
			"sudo apt install docker.io -y",
			"sudo snap install docker",
			"sudo apt-get install git",
			"sudo git clone https://github.com/Shirkenitin347/DevopsDemo",
			"cd DevopsDemo/Docker",
			"sleep 10",
			"sudo chmod 666 /var/run/docker.sock",
			"sudo systemctl enable docker",
			"sudo systemctl restart docker",
			"docker build -t webserver .",
			"docker run -it --rm -d -p 80:80 --name web webserver"
        ]
    }

  
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.webServer_storage_account.primary_blob_endpoint
  }
}
