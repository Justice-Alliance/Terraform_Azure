/*

The following links provide the documentation for the new blocks used
in this terraform configuration file

1. azurerm_resource_group - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group

*/

locals {
  resource_group_name="app-grp"
  location="North Europe"
  virtual_network={
    name="app-network"
    address_space="10.0.0.0/16"
  }
  subnets=[
    {
      name="subnetA"
      address_prefix="10.0.0.0/24"
    },
    {
      name="subnetB"
      address_prefix="10.0.1.0/24"
    }
  ]
}


 resource "random_pet" "stack_name" {
   length    = 2
   separator = "-"
   prefix    = "artifactory"
 }


# Creation d'un groupe de ressource
resource "azurerm_resource_group" "appgrp" {
  name     = local.resource_group_name
  location = local.location
}

# Creation d'un compte de stockage
resource "azurerm_storage_account" "appstore566565637" {
  name                     = "appstore566565637"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

# # Creation d'un blob storage
#   resource "azurerm_storage_container" "data" {
#    name                  = "data"
#    storage_account_name  = "appstore566565637"
#    container_access_type = "blob"
#    depends_on = [
#      azurerm_storage_account.appstore566565637
#    ]
#  }

# resource "azurerm_storage_blob" "maintf" {
#   name                   = "main.tf"
#   storage_account_name   = "appstore566565637"
#   storage_container_name = "data"
#  type                   = "Block"
#  source                 = "main.tf"
#  depends_on = [
#    azurerm_storage_container.data
#  ]
#}

# Creation d'un Vnet
resource "azurerm_virtual_network" "appnetwork" {
  name                = local.virtual_network.name
  location            = local.location
  resource_group_name = local.resource_group_name
  address_space       = [local.virtual_network.address_space]

  depends_on = [
    azurerm_resource_group.appgrp
  ]

  tags = {
    environment = "Production"
  }

}

# Creation de Subnets
  resource "azurerm_subnet" "subnetA" {
  name                 = local.subnets[0].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[0].address_prefix]
  service_endpoints = ["Microsoft.Storage"]

  depends_on = [
    azurerm_virtual_network.appnetwork
  ]
}

resource "azurerm_subnet" "subnetB" {
  name                 = local.subnets[1].name
  resource_group_name  = local.resource_group_name
  virtual_network_name = local.virtual_network.name
  address_prefixes     = [local.subnets[1].address_prefix]
  depends_on = [
    azurerm_virtual_network.appnetwork
  ]
}

# Create Public IP
# resource "azurerm_public_ip" "appip" {
#   name                = "app-ip"
#   resource_group_name = local.resource_group_name
#   location            = local.location
#   allocation_method   = "Static"
#   sku                 = "Standard"
#  depends_on = [
#    azurerm_resource_group.appgrp
#  ]
# }

# Creation d'un NSG
resource "azurerm_network_security_group" "appnsg" {
  name                = "app-nsg"
  location            = local.location
  resource_group_name = local.resource_group_name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

# Creation Vnet interface
resource "azurerm_network_interface" "appinterface" {
  name                = "appinterface"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnetA.id
    private_ip_address_allocation = "Dynamic"

  }
  depends_on = [
    azurerm_subnet.subnetA
  ]
}

#Association de la NSG au subnet A
resource "azurerm_subnet_network_security_group_association" "appnsglink" {
  subnet_id                 = azurerm_subnet.subnetA.id
  network_security_group_id = azurerm_network_security_group.appnsg.id
}

#Creation d'une machine virtuel
resource "azurerm_windows_virtual_machine" "appvm" {
  name                = "appvm"
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = "Standard_Ds2_v3"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  availability_set_id = azurerm_availability_set.appset.id
  network_interface_ids = [
    azurerm_network_interface.appinterface.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  depends_on = [
    azurerm_network_interface.appinterface,
    azurerm_resource_group.appgrp,
    azurerm_availability_set.appset,
    azurerm_virtual_network.appnetwork

  ]

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.appstore566565637.primary_blob_endpoint
  }
}

# resource "azurerm_managed_disk" "appdisk" {
#   name                 = "appdisk"
#   location             = local.location
#   resource_group_name  = local.resource_group_name
#   storage_account_type = "Standard_LRS"
#   create_option        = "Empty"
#   disk_size_gb         = "16"

#  }

#  resource "azurerm_virtual_machine_data_disk_attachment" "appdiskattach" {
#   managed_disk_id    = azurerm_managed_disk.appdisk.id
#   virtual_machine_id = azurerm_windows_virtual_machine.appvm.id
#   lun                = "0"
#   caching            = "ReadWrite"
# }

# Creation d'un availability set
resource "azurerm_availability_set" "appset" {
  name                = "app-set"
  location            = local.location
  resource_group_name = local.resource_group_name
  platform_fault_domain_count = 3
  platform_update_domain_count = 3

  depends_on = [
  azurerm_resource_group.appgrp
  ]
}


