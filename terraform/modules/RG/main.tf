resource "azurerm_resource_group" "WebServer" {
  name     = var.name
  location = var.location
}