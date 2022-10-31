resource "azurerm_linux_virtual_machine" "WebServer" {
  name                = "WebServer-machine"
  resource_group_name = azurerm_resource_group.WebServer.name
  location            = azurerm_resource_group.WebServer.location
  #custom_data = base64encode(file("scripts/init.sh"))
  size                = "Standard_B1s"
  admin_username      = "adminuser"

  network_interface_ids = [
    azurerm_network_interface.WebServer.id,
  ]
  
 source_image_reference {
    offer     = "UbuntuServer"
    publisher = "Canonical"
    sku       = "18.04-lts"
    version   = "latest"
  }
  
  
  admin_ssh_key {
    username   = "adminuser"
     public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  }