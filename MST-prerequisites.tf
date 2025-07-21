
#
# Important : MST VNet Prerequisites are specific with SPECIAL ORDER to create resources.
# https://portal.nutanix.com/page/documents/details?targetId=Disaster-Recovery-DRaaS-Guide-vpc_7_3:ecd-dr-mst-azure-create-an-mst-vnet-t.html 
# That is why you will find explicitge dependencies between resources.
#


# A VNet named MST-VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network

resource "azurerm_virtual_network" "TF_MSTVNet" {
  name                = var.MSTVNetName
  location            = var.Location
  resource_group_name = azurerm_resource_group.TF_RG.name
  address_space       = var.MSTVNetCIDR

    tags = {
        environment = "For MST"
    }
}


# A MST Subnet in MST VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
# https://www.ipaddressguide.com/cidr 
# Delegate this subnet to service: Microsoft.BareMetal/AzureHostedService.

resource "azurerm_subnet" "TF_MSTSubnet" {
  name                 = "MSTSubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_MSTVNet.name
  address_prefixes     = var.MSTSubnetCIDR

delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.BareMetal/AzureHostedService"
      actions = ["Microsoft.Network/networkinterfaces/*", "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}


# Azure NAT Gateway for MST VNet (Subnet MSTSubnet)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway
# cf. https://portal.nutanix.com/page/documents/details?targetId=Disaster-Recovery-DRaaS-Guide-vpc_7_3:ecd-dr-mst-azure-create-an-mst-vnet-t.html 
resource "azurerm_nat_gateway" "TF_NATGw_MST" {
  name                    = var.NATGwMSTName
  location                = azurerm_resource_group.TF_RG.location
  resource_group_name     = azurerm_resource_group.TF_RG.name
  sku_name                = "Standard"  # this is the only option available now
  tags = {
    fastpathenabled = "true"
  }
}


# Azure Public IP for NAT Gateway MST
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "TF_NATGw_PublicIP_MST" {
  name                = var.PublicIPMSTName
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}


# NAT Gateway (MST) and Public IP (MST) Association
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association
resource "azurerm_nat_gateway_public_ip_association" "TF_NATGw_PublicIP_Association_MST" {
  nat_gateway_id       = azurerm_nat_gateway.TF_NATGw_MST.id
  public_ip_address_id = azurerm_public_ip.TF_NATGw_PublicIP_MST.id
}


# Subnet and NAT Gateway Association (MST NAT GW + MST Subnet)
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association
resource "azurerm_subnet_nat_gateway_association" "TF_Subnet_NATGw_Association_MST" {
  subnet_id      = azurerm_subnet.TF_MSTSubnet.id
  nat_gateway_id = azurerm_nat_gateway.TF_NATGw_MST.id
}


# small timer to wait
# cf. https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
resource "time_sleep" "wait_30_seconds" {
  depends_on = [azurerm_subnet_nat_gateway_association.TF_Subnet_NATGw_Association_MST]

  create_duration = "30s"
}



# Azure has a known issue where routes are not propagated between peered VNets containing delegated subnets.
# Creating a dummy NIC connected to a dummy VNet forces Azure to propagate routes correctly.

# A Dummy Subnet in Hub VNet for VPN Gateway
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet

resource "azurerm_subnet" "TF_DummySubnet" {
  name                 = "DummySubnet"
  resource_group_name  = azurerm_resource_group.TF_RG.name
  virtual_network_name = azurerm_virtual_network.TF_MSTVNet.name
  address_prefixes     = var.MSTDummySubnetCIDR
  depends_on = [time_sleep.wait_30_seconds]
}


# A Dummy NIC in MST VNet
# a dummy NIC in the dummy subnet (this NIC need not be attached to any resource and can be standalone).
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
# This NIC is used to force Azure to propagate routes correctly between peered VNets  
resource "azurerm_network_interface" "TF_DummyNIC_MST" {
  name                = "DummyNIC-MST"
  location            = azurerm_resource_group.TF_RG.location
  resource_group_name = azurerm_resource_group.TF_RG.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.TF_DummySubnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# small timer to wait
# cf. https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
resource "time_sleep" "wait_30_seconds-2" {
  depends_on = [azurerm_network_interface.TF_DummyNIC_MST]

  create_duration = "30s"
}



###
### PEERING Between VNets : VNet Peering for MST VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/vnet_peering
# Peer MST VNet with Prism Central VNet and all Prism Elements VNets. Make sure peering is configured bidirectionally (allow traffic both ways).


# Peering between Cluster VNet and MST VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_Cluster2MST" {
  name                      = "Peer-ClusterVNet-to-MSTVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_Cluster_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_MSTVNet.id
  depends_on = [time_sleep.wait_30_seconds-2]
  timeouts {
    create = "60m"
  }
}

# small timer to wait
# cf. https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep
resource "time_sleep" "wait_30_seconds-3" {
  depends_on = [azurerm_network_interface.TF_DummyNIC_MST]

  create_duration = "30s"
}

resource "azurerm_virtual_network_peering" "TF_Peering_MST2Cluster" {
  name                      = "Peer-MSTVNet-to-ClusterVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_MSTVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_Cluster_VNet.id
  depends_on = [ azurerm_virtual_network_peering.TF_Peering_Cluster2MST, time_sleep.wait_30_seconds-3 ]
  timeouts {
    create = "60m"
  }
}


# Peering between PC VNet and MST VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering

resource "azurerm_virtual_network_peering" "TF_Peering_PC2MST" {
  name                      = "Peer-PCVNet-to-MSTVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_PC_VNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_MSTVNet.id
  depends_on = [time_sleep.wait_30_seconds-2]
  timeouts {
    create = "60m"
  }
}

resource "azurerm_virtual_network_peering" "TF_Peering_MST2PC" {
  name                      = "Peer-MSTVNet-to-PCVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_MSTVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_PC_VNet.id
  depends_on = [ azurerm_virtual_network_peering.TF_Peering_PC2MST, time_sleep.wait_30_seconds-3 ]
  timeouts {
    create = "60m"
  }
}


# Peering between MST VNet and Hub VNet
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering
# This peering is necessary for the MST VNet to communicate with the Hub VNet, which is used for Site-to-Site VPN connections.
# The MST VNet needs to be able to reach the Hub VNet for the Site-to-Site VPN connections to
# function correctly, allowing the MST VNet to communicate with on-premises networks through the Hub VNet.
# MANDATORY for  PilotLight scenario with on premises Nutanix Cluster.

resource "azurerm_virtual_network_peering" "TF_Peering_MST2Hub" {
  name                      = "Peer-MSTVNet-to-HubVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_MSTVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_HubVNet.id
  allow_virtual_network_access = true
  use_remote_gateways = true
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_MSTVNet, azurerm_virtual_network_gateway.TF_HubVPNGW ]
  timeouts {
    create = "60m"
  }
}


# Peering between Hub VNet and MST VNet

resource "azurerm_virtual_network_peering" "TF_Peering_Hub2MST" {
  name                      = "Peer-HubVNet-to-MSTVNet"
  resource_group_name       = azurerm_resource_group.TF_RG.name
  virtual_network_name      = azurerm_virtual_network.TF_HubVNet.name
  remote_virtual_network_id = azurerm_virtual_network.TF_MSTVNet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = false
  allow_gateway_transit = true
  use_remote_gateways = false
  depends_on = [ azurerm_virtual_network.TF_HubVNet, azurerm_virtual_network.TF_MSTVNet , azurerm_virtual_network_peering.TF_Peering_MST2Hub, time_sleep.wait_30_seconds-3 ]
  timeouts {
    create = "60m"
  }
}



# Storage Account for MST
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
# Nutanix recommends allowing access to the storage account only from the NAT gateway IP addresses used by the Azure Prism Central and MST subnets.
# This should be done by adding those IPs to the storage account firewall settings.
# Do not make the blob storage publicly accessible. This approach ensures secure access and protects your data from exposure to the public internet.
# cf. https://portal.nutanix.com/page/documents/details?targetId=Disaster-Recovery-DRaaS-Guide-vpc_7_3:ecd-dr-mst-azure-create-secure-storage-account-blob-container-t.html

resource "azurerm_storage_account" "TF_MST_Storage_Account" {
  name                     = var.MSTStorageAccountName
  resource_group_name      = azurerm_resource_group.TF_RG.name
  location                 = azurerm_resource_group.TF_RG.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  network_rules {
    default_action             = "Deny"
    # Add also your public IP (the workstation from where this terraform code is run)
    # If you don't do that, the creation of the storage container will fail
    # Replace the last IP in the following line with your public IP address (Outbound IP of your organization's network)
    ip_rules                   = [ azurerm_public_ip.TF_NATGw_PublicIP_MST.ip_address, azurerm_public_ip.TF_NATGw_PublicIP_PC.ip_address, "192.146.154.3" ] 
  }

  tags = {
    environment = "For MST"
  }
}


# A Blob container in the Storage Account for MST
# cf. https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
# cf. https://portal.nutanix.com/page/documents/details?targetId=Disaster-Recovery-DRaaS-Guide-vpc_7_3:ecd-dr-mst-azure-create-secure-storage-account-blob-container-t.html 
resource "azurerm_storage_container" "TF_MST_Storage_Container" {
  name                  = "mst-container"
  storage_account_name = azurerm_storage_account.TF_MST_Storage_Account.name 
  # Uncomment the following line if you want to use the storage account ID
  # This is not necessary if you are using the storage account name directly.
  # storage_account_id    = azurerm_storage_account.TF_MST_Storage_Account.id
  container_access_type = "private"

  depends_on = [azurerm_storage_account.TF_MST_Storage_Account]
}

