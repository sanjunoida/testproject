terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.26.0"
    }
  }
}
provider "azurerm" {
  features {}
  subscription_id = "247d5ce7-c0a1-4b83-8d9c-30b55c958e6c"

}
resource "azurerm_resource_group" "jaydeep_rg1" {
  name     = "Jaydeep_rg1"
  location = "Central India"

}
resource "azurerm_virtual_network" "vnet_Jay" {
  name                = "JaydeepVnet"
  address_space       = ["10.16.0.0/27"]
  location            = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name = azurerm_resource_group.jaydeep_rg1.name
}

resource "azurerm_subnet" "subnet_frontend" {
  name                 = "frontend_jay"
  resource_group_name  = azurerm_resource_group.jaydeep_rg1.name
  virtual_network_name = azurerm_virtual_network.vnet_Jay.name
  address_prefixes     = ["10.16.0.0/28"]
  depends_on           = [azurerm_virtual_network.vnet_Jay]
}
resource "azurerm_subnet" "subnet_backend" {
  name                 = "backend_jay"
  resource_group_name  = azurerm_resource_group.jaydeep_rg1.name
  virtual_network_name = azurerm_virtual_network.vnet_Jay.name
  address_prefixes     = ["10.16.0.16/28"]
  depends_on           = [azurerm_virtual_network.vnet_Jay]
}
resource "azurerm_mysql_flexible_server" "server-jay" {
  name                   = "server-jay"
  resource_group_name    = azurerm_resource_group.jaydeep_rg1.name
  location               = azurerm_resource_group.jaydeep_rg1.location
  administrator_login    = "Jaydeepc1985"
  administrator_password = "Oneday@1234"
  version                = "8.0.21"
  sku_name               = "B_Standard_B1ms"
  tags = {
    environment   = "dev"
    workload_type = "Dev/Test"


  }
}

#########################
# Public IPs
#########################
resource "azurerm_public_ip" "frontend_ip" {
  name                = "frontend-public-ip"
  location            = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name = azurerm_resource_group.jaydeep_rg1.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_public_ip" "backend_ip" {
  name                = "backend-public-ip"
  location            = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name = azurerm_resource_group.jaydeep_rg1.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

#########################
# Network Interfaces
#########################
resource "azurerm_network_interface" "nic_frontend" {
  name                = "nic-frontend-jay"
  location            = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name = azurerm_resource_group.jaydeep_rg1.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.frontend_ip.id
  }
}

resource "azurerm_network_interface" "nic_backend" {
  name                = "nic-backend-jay"
  location            = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name = azurerm_resource_group.jaydeep_rg1.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_backend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.backend_ip.id
  }
}

#########################
# Linux Virtual Machines
#########################
variable "admin_username" {
  default = "Jaydeepc1985"
}

variable "admin_password" {
  default = "Oneday@1231985"
}

resource "azurerm_linux_virtual_machine" "frontend_vm" {
  name                            = "frontend-vm-jay"
  location                        = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name             = azurerm_resource_group.jaydeep_rg1.name
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic_frontend.id,
  ]

  os_disk {
    name                 = "frontend-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    role = "frontend"
  }
}

resource "azurerm_linux_virtual_machine" "backend_vm" {
  name                            = "backend-vm-jay"
  location                        = azurerm_resource_group.jaydeep_rg1.location
  resource_group_name             = azurerm_resource_group.jaydeep_rg1.name
  size                            = "Standard_B1s"
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.nic_backend.id,
  ]

  os_disk {
    name                 = "backend-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  tags = {
    role = "backend"
  }
}
