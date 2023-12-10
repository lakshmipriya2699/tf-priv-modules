data "azurerm_resource_group" "rg01" {
  name = var.rg_name
}
resource "azurerm_virtual_network" "name" {
  name = var.vnet_name
  location = var.region
  resource_group_name = var.rg_name
  address_space = var.vnet_address
}

resource "azurerm_public_ip" "example" {
  name                = var.rmpublicIP
  resource_group_name = data.azurerm_resource_group.rg01.name
  location            = data.azurerm_resource_group.rg01.location
  allocation_method   = "Static"

  tags ={
    environment= var.tag_env
  }
}

resource "azurerm_network_interface" "main" {
  name                = var.nic_name
  location            = data.azurerm_resource_group.rg01.location
  resource_group_name = data.azurerm_resource_group.rg01.name

  ip_configuration {
    name                          = "testconfiguration3"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "azurerm_storage_account" "main" {
  name                     = "bootdiag20092018001pll"
  resource_group_name      = data.azurerm_resource_group.rg01.name
  location                 = data.azurerm_resource_group.rg01.location
  account_tier             = split("_", var.boot_diagnostics_sa_type)[0]
  account_replication_type = split("_", var.boot_diagnostics_sa_type)[1]
}
 
resource "azurerm_virtual_machine" "main" {
  name                  = var.vm_name
  location              = data.azurerm_resource_group.rg01.location
  resource_group_name   = data.azurerm_resource_group.rg01.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = var.vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  storage_os_disk {
    name              = var.os_disk_name
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.computer_name
    admin_username = var.admin_username
    //admin_password = var.vm_password
  
  }
  
 os_profile_linux_config {
  disable_password_authentication = true
  ssh_keys {
    path     = "/home/linuxusr/.ssh/authorized_keys"
    key_data = tls_private_key.linux_key.public_key_openssh
  }
}
boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.main.primary_blob_endpoint
  }
  /*os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }*/

}
 resource "null_resource" "copy-file" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "file" {
    source = "test1.txt"
    destination = "/home/linuxusr/test1.txt"
  }

  connection {
    type        = "ssh"
    user        = "linuxusr"
    private_key = tls_private_key.linux_key.private_key_pem
    host        = azurerm_public_ip.example.ip_address
  }
}
