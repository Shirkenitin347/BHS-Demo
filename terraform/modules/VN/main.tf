resource "azurerm_virtual_network" "WebServer" {
  name                = "WebServer-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.WebServer.location
  resource_group_name = azurerm_resource_group.WebServer.name
}

resource "azurerm_subnet" "WebServer" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.WebServer.name
  virtual_network_name = azurerm_virtual_network.WebServer.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vm_public_ip"
  resource_group_name = azurerm_resource_group.WebServer.name
  location            = azurerm_resource_group.WebServer.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "WebServer" {
  name                = "WebServer-nic"
  location            = azurerm_resource_group.WebServer.location
  resource_group_name = azurerm_resource_group.WebServer.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.WebServer.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}