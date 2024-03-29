﻿/*

The following links provide the documentation for the new blocks used
in this terraform configuration file

1. azurerm_virtual_machine_scale_set_extension - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_scale_set_extension

*/

# The storage account will be used to store the script for Custom Script extension

resource "azurerm_storage_account" "vmstore4577687" {
  name                     = "vmstore4577687"
  resource_group_name      = "app-grp"
  location                 = "North Europe"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind = "StorageV2"
  depends_on = [
    azurerm_resource_group.appgrp
  ]
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "vmstore4577687"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.vmstore4577687
    ]
}

resource "azurerm_storage_blob" "IISConfig" {
  name                   = "IIS_Config.ps1"
  storage_account_name   = "vmstore4577687"
  storage_container_name = "data"
  type                   = "Block"
  source                 = "IIS_Config.ps1"
   depends_on=[azurerm_storage_container.data,
    azurerm_storage_account.vmstore4577687]
}


resource "azurerm_virtual_machine_scale_set_extension" "scalesetextension" {
  name                 = "scalesetextension"
  virtual_machine_scale_set_id   = azurerm_windows_virtual_machine_scale_set.appset.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  depends_on = [
    azurerm_storage_blob.IISConfig
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.vmstore4577687.name}.blob.core.windows.net/data/IIS_Config.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file IIS_Config.ps1"
    }
SETTINGS

}
