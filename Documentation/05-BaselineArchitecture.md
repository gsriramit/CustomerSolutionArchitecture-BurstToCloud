# Mission-critical baseline architecture with network controls

## Architecture

![High Availability - BurstToCloud](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/58cafd1b-de51-4a5b-9032-4618c89970ea)


## Global Resources
**1.Azure Traffic Manager-** The Traffic Manager serves as the global DNS load balancer. Since the traffic manager does not sit in the data path of the end user traffic, the endpoints load balanced by the Traffic manager should be public endpoints. This topic has been discussed in a great detail in the Networking Design Areas page   
### Global Monitoring Resources 
**2.Log Analytics Workspaces-** The LA workspace is used as the primary sink to ingest the infrastrucure logs from all the global resources. These logs can then be further analyzed  
**3.Application Insights-** The global instance of app insights is used to ingest the application logs from the Logic App. These logs will help in analyzing the user flows involving the Logic App  
**4.Azure Private DNS Zone-** By design, the private DNS zone for the data platform is created as a global resource. The logical SQL servers created for the Azure SQL DBs in each of the regional stamps have their private endpoint entries in this private DNS zone  
**5.Azure Monitor Autoscale-** The autoscale configuration created from the Azure monitor lets us configure the autoscale rule for the VMSS instance in the secondary region.  
**6.Azure Logic App-** An instance of Logic app that receives alerts from the primary instance of app-inisghts then triggers a workflow that updates the Traffic Manager weights. This is the flow that handles the bursts to the cloud and back  
**7.Storage Account-** A global instance of storage account maintains the golden images to be used for the Virtual Machine ScaleSets and other automation scripts (if any)  

## Regional Resources
**1.Regional Public Load Balancer-** The Azure Load balancer in each of the Azure stamps receives the end user traffic on its public frontend IP. The traffic is then balanced across the virtual machines scaleset instances in its backend pool  
**2.Virtual Machine Scale Sets-** VMSS is the compute infrastructure that hosts the application. The scale set is configured for scaling based on an **Application Metric read from the targeted Application Insights Instance**. In this solution, we have used the **Request-Rate** as the key metric
**3.Azure SQL DB-** Azure SQL DB has been used in this solution to make the implementation simpler. However, the actual choice for customers can be SQL hosted on Azure Virtual Machines or Azure SQL Managed Instance. The DB hosts the application state. Azure SQL DB in this case has been configured to use Geo-replicas for high-availability
**4.Virtual Networks-** Each stamp created per region will have one virtual network in it. The Virtual networks across the regions should not have an overlapping address space as we peer the these VNETS for the cross-region data platform traffic. The Vnets have been segmented in the following way  

| Segment                             | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Security                                                                                                                                                                                                                                                                                                                                                            |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Application Platform/Web App Subnet | This subnet hosts the Virtual Machine scale sets. Plan the address space of this subnet to accommodate for the increase in the ip consumption from the scale out of the scale set. \*\*Note\*\* The Azure Public Load Balancer does not expect the user to allocate a subnet for its instances to be placed. However, internally the LB will be linked to the subnet (the instances that receive the traffic and doing a NAT to send the traffic to the backend vmss instances) | A NSG is attached to this subnet that satisfies the requirements of the Standard Load balancer that denies inbound traffic by default. We allow the https/443 port. Apart from this we security group can include any other rules needed for the scale set                                                                                                          |
| Private Endpoint Subnet             | This subnet is used to provide the private IP addresses required for the identified PAAS services, namely Azure KeyVault and Azure SQL DB (logical server). Allocate an address space that can handle the growing needs of private endpoints per region                                                                                                                                                                                                                         | NSG should be applied for this subnet. \*\*Note:\*\*This has not been implemented in this solution but will be done in the bear future. More read a) https://azure.microsoft.com/en-us/updates/general-availability-of-network-security-groups-support-for-private-endpoints/ b) https://journeyofthegeek.com/2022/03/12/private-endpoints-revisited-nsgs-and-udrs/ |
| Bastion Subnet                      | This subnet hosts the bastion host. A small subnet with a /28 or a /29 should be sufficient. We have created only one bastion subnet in this solution and utilized Bastion support for connected networks to RDP into the machines across the regions.                                                                                                                                                                                                                          | No explicit NSG has been applied to this subnet. For highly secured environments, the following guide can be used- https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg                                                                                                                                                                                      |  

**Note:**   
1. We have not implemented security for the egress traffic. The suggested best practice is to deploy an Azure Firewall or a third party NVA that can check all the egress traffic for security issues. An AzureFirewallSubnet needs to be allocated for the firewall.  
2. The regional observability resources i.e. Log Analytics workspace and Application Insights have also not been made private using AMPLS (Azure monitor private link service). If this is being done, then there needs to be a addresses in the private endpoint subnet for these resources too.

### Regional Observability Resources
**Application Insights-** The app insights resources in the primary region that represents on-premise will capture the application logs and metrices. Even if this solution is implemented in a proper hybrid environment, it is *advisable to have an Azure App insights resources that runs on Azure in the same region as that of the on-premise stamp*.The application should be configured to send the logs and metrics to insights sink. One of the Azure monitor autoscale rules that gets triggered during the first burst is based on the metrics read from the primary instance of App Insights. The Logic app that adjusts the weights of the Traffic Manager is also based on the alerts triggered from the primary instance of insights.  
The Insights instance in the secondary azure region will be configured to receive app logs and metrics from the apps in the secondary Azure region. We have not implemented the subsequent cases of scale out in the secondary region but one or more Autoscale rules (**for scaleout to handle the traffic growth beyond the initial burst to cloud**) and Logic app to further adjust the traffic manager weights should be based on this instance of app insights  
**Log Analytics Workspace-** The Log analytics workspace will be configured as the primary sink for all the infrastructure and diagnostics logs received from the regional resources

## Data Flow

![High Availability - BurstToCloud-FlowDiagram](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/19ce16ce-0048-4679-b404-6a9a53ef0138)


1. The Traffic manager initially has 99 and 1 as the weights assigned to the on-premise and Azure endpoints. The Azure endpoint would be disabled to begin with. The end user traffic would be sent to the on-premise/primary endpoint i.e., the Azure External Load Balancer in this case  
![Screenshot 2023-04-12 220134](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/a801d882-4b1d-41e7-98ce-ddc84bf844aa)

2. Azure Load balancer routes the traffic to one of the healthy vmss instances in its backend pool
3. The application then connects to the data platform (Azure SQLDB) through its private endpoint and completes the data access operations
   - **Note:** The return traffic flow has been skipped for brevity
4. Azure monitor autoscale has been configured to scale out the VMSS instances in the secondary region (that is on warm standby with just one running instance). Application insights metrics would trigger the autoscale rule according to the config (e.g. Request rate > 5000/second)
   - 4.1 Auto scale rule scales out VMSS by 2 instances  
![Screenshot 2023-04-12 215446](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/b51a6383-a5ec-4f77-92e0-28ce3a6d19e1)

5. When the traffic further increases (to the configured value of 90% of on-premises' threshold), the alert from the primary app insights instance gets executed
   - 5.1 The action group for the alert executes the logic app flow. The logic app now changes the weights of the Traffic manager (to say 84:16) and also enables the Azure/secondary endpoint  
![Screenshot 2023-04-13 182614](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/8bc8ba93-906f-4ea4-9b28-3d70228cb76e)  

![Screenshot 2023-04-12 215331](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/cad846ff-8f8c-4ece-9cb8-aee22a96f08d)

6. Now 16%  of client's traffic would be sent to the Azure endpoint, i.e., the Azure public LB 
7. The load balancer would route the traffic to backend vmss instances
8. The app would now send all the read traffic to geo read-replica in the secondary region and the write traffic to the primary replica in the primary region. The connections to these replicas happen through the corresponding regional private endpoints  

**Note:** Once the rate of requests decreases to a level that the on-premises can alone handle, the operations elaborated in the steps above happen in reverse. The autoscale rule would execute the scale in operation to bring down the Azure VMSS back to warm standby state of 1 instance. The logic app workflow would revert the weights back to 99 and 1 so that the Azure endpoint does not have to handle any active traffic  
![Screenshot 2023-04-12 220109](https://github.com/gsriramit/CustomerSolutionArchitecture-BurstToCloud/assets/13979783/84a01380-7737-49a2-99fa-52a9e14fa7ae)



