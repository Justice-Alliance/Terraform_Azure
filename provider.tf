
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.8.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "6912d7a0-bc28-459a-9407-33bbba641c07"
  client_id       = "08d82452-5ee9-4b5b-96ea-aec56d9db182"
  client_secret   = "oc38Q~D5P_jTpGSStayL3_3pT2Kqm2olimm2Ja_p"
  tenant_id       = "70c0f6d9-7f3b-4425-a6b6-09b47643ec58"
  features {}
}