resource "azurerm_network_security_group" "Webserver" {
  name                = "WebServer"
  location            = azurerm_resource_group.WebServer.location
  resource_group_name = azurerm_resource_group.WebServer.name

security_rule {
       name = "http"
       priority = 100
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "80"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }

   security_rule {
       name = "https"
       priority = 200
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "443"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }

   security_rule {
       name = "ssh"
       priority = 300
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "22"
       source_address_prefix = "*"
       destination_address_prefix = "*"
   }
}

resource "azurerm_network_interface_security_group_association" "associationtest" {
  network_interface_id      = azurerm_network_interface.WebServer.id
  network_security_group_id = azurerm_network_security_group.BHS.id
}