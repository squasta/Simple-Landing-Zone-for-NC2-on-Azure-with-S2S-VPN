## Nutanix Cloud Cluster (NC2) on Azure - Simple Landing Zone for POC

## Scenario interconnexion with a Site to Site VPN on a Hub and Spoke topology (NO Azure Virtual WAN)

This repo contains Terraform files to deploy all Azure network components needed to deploy Nutanix Cloud Cluster(NC2) on Azure Baremetal.

This is for the scenario with an interconnexion with a VPN site to Site ([Azure VPN Gateway](https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpngateways)) and [Hub and Spoke topology without vWAN](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke?tabs=cli)

This code include a Hub VNet with an Azure VPN Gateway. You need an on-premise / other cloud VPN device to complete the configuration and establish IPsec tunnels

This code includes the network pre requisites to use Multicloud Snapshot Technology with Azure Blob Storage

<img width='400' src='./images/PlaneLZ.png'/> 


## Prerequisites

- All prerequisites for NC2 : https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-getting-ready-for-deployment-c.html
- For AOS > 6.7 (on AOS 6.7 or higher, Flow Gateways are deployed in a dedicated Flow Gateway VNet).
- If you want to test Multicloud Snapshot Techolology with Azure Blob Storage, choose AOS >= 7.3


- An Azure Subscription with enough privileges (create RG, Azure networking...)
- Azure CLI 2.57 or >: <https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest>
   And you need to activate features that are still in preview and add extension aks-preview to azure CLI (az extension add --name aks-preview)
- Terraform CLI 1.5 or > : <https://www.terraform.io/downloads.html>

You can also clone this repo in your [Azure Cloud Shell](https://shell.azure.com/) (that has all tools installed)

## Step by step operations

Edit [example-configuration.tfvars](example-configuration.tfvars) to define your Azure resources names, your networks CIDRs, VPN tunnel Sharekeys...

Rename example-configuration.tfvars to configuration.tfvars

 
<img width='800' src='./images/AzureLZVPNNoWAN.png'/> 

If you want to connect to Prism Element or Prism Central through Internet, there is an option to enable an [Azure Bastion](https://learn.microsoft.com/en-us/azure/bastion/bastion-overview) instance and a Windows Server 2025 Virtual Machine Jumbox. 

1. Terraform Init phase  

```bash
terraform init
```

2. Terraform Plan phase

```bash
terraform plan --var-file=configuration.tfvars
```

3. Terraform deployment phase (add TF_LOG=info at the beginning of the following command line if you want to see what's happen during deployment)

```bash
terraform apply --var-file=configuration.tfvars
```


4. Wait until the end of deployment (It should take around an hour because of Azure VPN Gateway that needs around 50 minutes to deploy)

Important :exclamation: : If the deployment finishes with an error on peering, just re execute the previous command (step 3) !

After the Landing Zone deployment is successfull, you can test connectivity with on-premises or other Azure VNet using "on prem"VM and "on Hub VM".

5. Go to Nutanix [NC2 Portal](https://cloud.nutanix.com) https://cloud.nutanix.com and start your Nutanix Cluster deployment wizard. In steps 4 (Network), 5 (Prism Central) and 6 (Flow Networking) select Azure VPN, the Virtuals Networks and Subnets created in step 3 using Terraform

<img width='800' src='./images/Step4.png'/> 

<img width='800' src='./images/Step5.png'/> 

<img width='800' src='./images/Step6.png'/> 

6. If you enabled AzureBastion and Jumpbox VM, you can login to the Jumbox VM and connect Prism Element or Prism Central through a web browser. 

Notes : 
 - If you don't need Azure Bastion or Jumbox 24/7. You can simply enable (create) or disable (delete) these resources in [example-configuration.tfvars](example-configuration.tfvars) file (EnableJumboxVM and EnableAzureBastion | 0= disabled , 1=enabled)


7. Use the solution and configure Nutanix features like Flow VPC, categories...
   - Create and configure your Nutanix Flow VPC (all configurations steps are [here](https://squasta.github.io/configurationvpcazure.html))
   - Deploy User VM on Nutanix Cluster
   - Test connectivity of UVM. (cf. https://portal.nutanix.com/page/documents/details?targetId=Nutanix-Cloud-Clusters-Azure:nc2-clusters-azure-network-connectivity-uvm-c.html)

8. When you want to destroy the Nutanix Cloud Cluster, use the NC2 Portal/Console (https://cloud.nutanix.com) to terminate it.

9. After cluster terminaison, you can destroy the landing zone using the following command : 
```bash
terraform destroy --var-file=configuration.tfvars
```

## How much does it cost to test this landing zone ?

It's cheap to test and customize this simple landing zone. Of course if you don't  need some resources (like VM or Bastion) except for testing, you should disabled them.

You can use **infracost** (available on https://www.infracost.io/) to check the estimate price for 1 month.

```bash
infracost breakdown --path .
```

 Here is an example for Azure Germany West Central region

 :exclamation: Important : this landing zone cost estimation does not include the cost of Azure Baremetal instance(s) used as node(s) in the Nutanix Cluster because Baremetal pricing is not yet available through Azure Pricing API.

<img width='800' src='./images/InfracostNC2LDZAzure.png'/> 

 Please have a look of metal instances prices here : https://azure.microsoft.com/en-us/pricing/details/nutanix-on-azure/?cdn=disable. Pricing is per instance-hour consumed for each instance, from the time an instance is launched until it is terminated or stopped.

 
