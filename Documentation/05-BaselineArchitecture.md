# Mission-critical baseline architecture with network controls

## Architecture

![HighAvailability-BurstToCloud-Architecture-A](https://user-images.githubusercontent.com/13979783/236836546-2c6e2463-4c2e-4277-89a8-8a0198b88def.png)

## Global Resources
### Azure Traffic Manager
The Traffic Manager serves as the global DNS load balancer. Since the traffic manager does not sit in the data path of the end user traffic, the endpoints load balanced by the Traffic manager should be public endpoints. This topic has been discussed in a great detail in the Networking Design Areas page  
### Global Monitoring Resources 
#### Log Analytics Workspaces
The LA workspace is used as the primary sink to ingest the infrastrucure logs from all the global resources. These logs can then be further analyzed
#### Application Insights
The global instance of app insights is used to ingest the application logs from the Logic App. These logs will help in analyzing the user flows involving the Logic App
### Azure Private DNS Zone
By design, the private DNS zone for the data platform is created as a global resource. The logical SQL servers created for the Azure SQL DBs in each of the regional stamps have their private endpoint entries in this private DNS zone
### Azure Monitor Autoscale
The autoscale configuration created from the Azure monitor lets us configure the autoscale rule for the VMSS instance in the secondary region. 
### Azure Logic App
An instance of Logic app that receives alerts from the primary instance of app-inisghts then triggers a workflow that updates the Traffic Manager weights. This is the flow that handles the bursts to the cloud and back
### Storage Account
A global instance of storage account maintains the golden images to be used for the Virtual Machine ScaleSets and other automation scripts (if any)

## Regional Resources
### Regional Public Load Balancer
The Azure Load balancer in each of the Azure stamps receives the end user traffic on its public frontend IP. The traffic is then balanced across the virtual machines scaleset instances in its backend pool
### Virtual Machine Scale Sets
VMSS is the compute infrastructure that hosts the application. The scale set is configured for scaling based on an **Application Metric read from the targeted Application Insights Instance**. In this solution, we have used the **Request-Rate** as the key metric
### Azure SQL DB
Azure SQL DB has been used in this solution to make the implementation simpler. However, the actual choice for customers can be SQL hosted on Azure Virtual Machines or Azure SQL Managed Instance. The DB hosts the application state. Azure SQL DB in this case has been configured to use Geo-replicas for high-availability  
