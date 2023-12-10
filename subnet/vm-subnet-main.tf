data "azurerm_resource_group" "rg01" {
  name = var.rg_name
}


# We want to save the private key to our machine
# We can then use this key to connect to our Linux VM

resource "azurerm_subnet" "example" {
  #count = length(var.subnet_name)
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.rg01.name
  virtual_network_name = var.vnet_name
  address_prefixes     = [var.subnet_CIDR]
}

output "sub-id" {
  value = azurerm_subnet.example.subnet_id
}
