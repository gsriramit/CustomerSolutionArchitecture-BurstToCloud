# Design Areas

## Application Platform Design
### Global distribution of platform resources  
**Excerpt from the official doc**: The mission-critical design methodology requires a multi-region deployment. This model ensures regional fault tolerance, so that the application remains available even when an entire region goes down.  
In this solution, we have considered an Active-Hot-Standy deployment model. This design can help us handle the business case of the Azure stamp(s) having have to handle the excessive traffic alone and need not be a full blown deployment.The global resources in this architecture include the Traffic Manager (global load balancer), Logic App, storage account and Azure monitoring solutions incuding a Log analytics workspace and an app-insights instance. As opposed to the guidance in the Mission-Critical architecture, the database that stores the application's state cannot be a global resource. This and a few other deviations from the Mission-Critical standards have been explained in the appropriate sections  
#### Design Considerations & Recommendations
1. **Regional and Zonal Capabilities**-  The proposed architecture comes with the following suggestions 
   - Choose an Azure region (for the burst tarffic) within the same geography
   - The region needs to be selected such that it offers the support for Availability zones. This ensures HA of the regional deployment stamps. **Note**: Not all regions in the US have the availability zones support. The standard proposes to make use of the Availability set where Availability zones are not available
   - The selected region also needs to support the services that have been chosen for this workload
   - Another important consideration is the availability of enough amount of resources in the secondary region. E.g., if your subscription does not have enough number of compute cores in the selected region, then the scale-out action of the VMSS would fail and this would affect in the failure of the requests
     - This contraint places a direct emphasis on the design practice of doing a *Resource Requirement Etimation*  and *Platform Capacity Assessment** and  and creating requests for resources that are to be approved
2. **Defining RPO and RTO** -  These have not been defined in this solution as we have not exercised a direct DR scenario in here. However, the general guidance is to define the expected RPO and RTO and see if the multi-region design is capable of supporting these requirements. **TBD**: Add information on the RPO and RTO support that Azure SQLDB Business Critical Tier provides
3. **Safe deployment**- The [Azure safe deployment practice (SDP) framework](https://azure.microsoft.com/blog/advancing-safe-deployment-practices) ensures that all code and configuration changes (planned maintenance) to the Azure platform undergo a phased rollout. 
4. **CDN, Edge-Caching** - It is a suggested practice to use the features of Content Delivery networks and edge caching if the workload is HTTP based and Application Delivery Network capabilities (i.e. accelerated delivery) are required. These are baked into Azure Front Door. This solution does not use AFD for reasons that would be elaborated in a separate section

### Constrained migrations via IaaS
This section from the documentation talks about the scenario where a workload has not been modernized yet, i.e. usage of containers or other cloud native technologies. We have taken such a scenario for our solution implementation where in the assumption is the web application runs on Virtual Machines on-premise. So the Azure based deployment stamps would also run the workload on Azure VMSS
#### Design Considerations and Recommendations
1. **Operational Costs of the VMs** - The operational costs of using IaaS virtual machines are significantly higher than the costs of using PaaS services because of the management requirements of the virtual machines and the operating systems. Managing virtual machines necessitates the frequent rollout of software packages and updates [**this is a direct excerpt from the documentation**]
2. **Availability of VMs** - To make sure the compute part of the workload is Highly Available, we have chosen the VMSS with autoscaling and the instances to be placed across the availability zones
3. 

