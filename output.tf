# Data source to fetch the actual public IP
data "azurerm_public_ip" "TF_VPN_GW_PIP" {
  name                = azurerm_public_ip.TF_HubVPNGWPublicIP.name
  resource_group_name = azurerm_resource_group.TF_RG.name
  depends_on          = [azurerm_virtual_network_gateway.TF_HubVPNGW]
}

# Output the public IP address
output "vpn_gateway_public_ip" {
  value = data.azurerm_public_ip.TF_VPN_GW_PIP.ip_address
}