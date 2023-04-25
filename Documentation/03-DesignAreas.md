# Design Areas

## Application Platform Design
### Global distribution of platform resources  
**Excerpt from the official doc**: The mission-critical design methodology requires a multi-region deployment. This model ensures regional fault tolerance, so that the application remains available even when an entire region goes down.  
In this solution, we have considered an Active-Hot-Standy deployment model. This design can help us handle the business case of the Azure stamp(s) having have to handle the excessive traffic alone and need not be a full blown deployment.The global resources in this architecture include the Traffic Manager (global load balancer), Logic App, storage account and Azure monitoring solutions incuding a Log analytics workspace and an app-insights instance. As opposed to the guidance in the Mission-Critical architecture, the database that stores the application's state cannot be a global resource. This and a few other deviations from the Mission-Critical standards have been explained in the appropriate sections  
### Design Considerations & Recommendations
1. **Regional and Zonal Capabilities**-  The proposed architecture comes with the following suggestions 
   - Choose an Azure region (for the burst tarffic) within the same geography
   - The region needs to be selected such that it offers the support for Availability zones. This ensures HA of the regional deployment stamps. **Note**: Not all regions in the US have the availability zones support. The standard proposes to make use of the Availability set where Availability zones are not available
   - The selected region also needs to support the services that have been chosen for this workload
   - Another important consideration is the availability of enough amount of resources in the secondary region. E.g., if your subscription does not have enough number of compute cores in the selected region, then the scale-out action of the VMSS would fail and this would affect in the failure of the requests
     - This contraint places a direct emphasis on the design practice of doing a *Resource Requirement Etimation*  and *Platform Capacity Assessment** and  and creating requests for resources that are to be approved
2. **Defining RPO and RTO** -  These have not been defined in this solution as we have not exercised a direct DR scenario in here. However, the general guidance is to define the expected RPO and RTO and see if the multi-region design is capable of supporting these requirements. **TBD**: Add information on the RPO and RTO support that Azure SQLDB Business Critical Tier provides
3. 
