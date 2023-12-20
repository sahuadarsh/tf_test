#creating two resource group
resource "azurerm_resource_group" "rg1" {
  name     = "example_rg1"
  location = "West Europe"
}

resource "azurerm_resource_group" "rg2" {
  name     = "example_rg2"
  location = "East US"
}

#creating vnet
resource "azurerm_virtual_network" "vnet1" {
  name                = "example-network1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }

 /* subnet {
    name           = "subnet2"
    address_prefix = "10.0.2.0/24"
  }
  tags = {
    environment = "Dev"
  }*/
}

#creating separate subnet
resource "azurerm_subnet" "subnet2" {
  name                 = "internal_subnet2"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.2.0/24"]
}


#creating nic by using looping
variable "nic_names"{
  type = list(string)
  default = ["nic-1", "nic-2"]
} 
/*variable "rg_names"{
  type = list(string)
  default = ["rg-1", "rg-2"]
}*/
resource "azurerm_network_interface" "nic" {
  count = length(var.nic_names)
  name                = var.nic_names[count.index]
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

# create virtual machine by looping
variable "vm_names"{
  type = list(string)
  default = ["vm-1", "vm-2"]
} 

resource "azurerm_windows_virtual_machine" "vm" {
  count = length(var.vm_names)
  name                = var.vm_names[count.index]
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
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
