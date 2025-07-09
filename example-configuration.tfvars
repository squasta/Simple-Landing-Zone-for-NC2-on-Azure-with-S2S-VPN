#
#### this file is a tfvars sample that you can use to define all values for
#### the landing zone deployment in your Azure Subscription
#
ResourceGroupName="RG-NC2"
Location="germanywestcentral"    # this must be an Azure region with baremetal
#
# Cluster (baremetal hosts) Azure Virtual Network
#
ClusterVnetName="cluster-mgmt-vnet-germanywestcentral"
ClusterVnetCIDR=["192.168.10.0/24"]
ClusterSubnetName="cluster-mgmt-subnet-germanywestcentral"
ClusterSubnetCIDR=["192.168.10.0/24"]
# 
# Prism Central Azure Virtual Network
#
PCVnetName="pc-vnet-germanywestcentral"
PCVnetCIDR=["192.168.11.0/24"]
PCSubnetName="cluster-pc-subnet-germanywestcentral"
PCSubnetCIDR=["192.168.11.0/25"]
NATGwClusterName="mgmt-nat-gw-germanywestcentral"
PublicIPClusterName="publicIP-mgmt-nat-gw-germanywestcentral"
#
# Flow Gateway(s) Azure Virtual Network
#
FGWVnetName="fgw-vnet-germanywestcentral"
FGWVnetCIDR=["192.168.12.0/23"]
FgwExternalSubnetName="fgw-external-subnet-germanywestcentral"
FgwExternalSubnetCIDR=["192.168.12.0/24"]
FgwInternalSubnetName="fgw-internal-subnet-germanywestcentral"
FgwInternalSubnetCIDR=["192.168.13.0/25"]
BGPSubnetName="bgp-subnet-germanywestcentral"
BGPSubnetCIDR=["192.168.13.128/25"]
NATGwPCName="pc-nat-gw-germanywestcentral"
PublicIPPCName="publicIP-PC-nat-gw-germanywestcentral"
#
# Azure Bastion (1= Enable, 0= Not deploy)
#
EnableAzureBastion=1
PublicBastionIPName="bastion-public-ip-germanywestcentral"
AzureBastionHostName="bastion-host-germanywestcentral"
AzureBastionSubnetCIDR=["192.168.11.128/25"]
AzureBastionSKU="Standard"
#
# Jumbox VM (1= Enable, 0= Not deploy)
#
EnableJumboxVM=1
AdminUsername="adminNC2"
VMBastionNicName="jumbox-nic-germanywestcentral"
VMJumpboxName="jumbox-germanywestcentral"
HostnameVMJumbox="myjumbox"
#
# Hub Azure Virtual Network (this is for an Hub and Spoke Topology)
#
HubVNetName= "hub-vnet-germanywestcentral"
HubVNetCIDR=["172.16.0.0/16"]
HubSubnetCIDR=["172.16.0.0/24"]
HubVPNGWSubnetCIDR=["172.16.250.0/27"]
#
# Azure VPN Gateway for Site to Site VPN with on premises Datacenter
#
VPNSiteToSiteSharedKey="mysharedkey1234"  # Replace with your actual shared key for the VPN connection
NATGwFGWName="fgw-nat-gw-germanywestcentral"
PublicIPFGWName="publicIP-fgw-nat-gw-germanywestcentral"
PublicIPRemoteVPNGateway="1.2.3.4"        # Replace with your actual public IP for the remote VPN gateway
OnPremisesDataCenterCIDRs=["10.0.0.0/16"] # Replace with all IP ranges that will be on the other side of VPN tunnel
#
# For Multicloud Snapshot Technology DR with Azure Blob Storage (AOS 7.3 and more)
#
MSTStorageAccountName="mststorageaccount"   # this name must be unique
