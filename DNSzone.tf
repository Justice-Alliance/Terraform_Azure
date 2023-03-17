/*

The following links provide the documentation for the new blocks used
in this terraform configuration file

1. azurerm_dns_zone - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone

2. azurerm_dns_a_record - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record

*/


resource "azurerm_dns_zone" "publiczone" {
  name                = "cloudportalhub.com"
  resource_group_name = local.resource_group_name
}

output "server_names"{
  value=azurerm_dns_zone.publiczone.name_servers
}

// Pointing the domain name to the load balancer
resource "azurerm_dns_a_record" "load_balancer_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.publiczone.name
  resource_group_name = local.resource_group_name
  ttl                 = 360
  records             = [azurerm_public_ip.loadip.ip_address]
}

