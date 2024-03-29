# Design Areas

## 1. Application Platform Design
### Global distribution of platform resources  
**Excerpt from the official doc**: The mission-critical design methodology requires a multi-region deployment. This model ensures regional fault tolerance, so that the application remains available even when an entire region goes down.  
In this solution, we have considered an Active-Hot-Standy deployment model. This design can help us handle the business case of the Azure stamp(s) having have to handle the excessive traffic alone and need not be a full blown deployment.The global resources in this architecture include the Traffic Manager (global load balancer), Logic App, storage account and Azure monitoring solutions incuding a Log analytics workspace and an app-insights instance. As opposed to the guidance in the Mission-Critical architecture, the database that stores the application's state cannot be a global resource. This and a few other deviations from the Mission-Critical standards have been explained in the appropriate sections  
#### Design Considerations & Recommendations
1. **Regional and Zonal Capabilities**-  The proposed architecture comes with the following suggestions 
   - Choose an Azure region (for the burst tarffic) within the same geography
   - The region needs to be selected such that it offers the support for Availability zones. This ensures HA of the regional deployment stamps. **Note**: Not all regions in the US have the availability zones support. The standard proposes to make use of the Availability set where Availability zones are not available
   - The selected region also needs to support the services that have been chosen for this workload
   - Another important consideration is the availability of enough amount of resources in the secondary region. E.g., if your subscription does not have enough number of compute cores in the selected region, then the scale-out action of the VMSS would fail and this would result in the failure of the requests
     - This contraint places a direct emphasis on the design practice of doing a *Resource Requirement Etimation*  and *Platform Capacity Assessment** and  and creating requests for resources that are to be approved
2. **Defining RPO and RTO** -  The RPO and RTO of the entire system have not been defined in this solution as we have not exercised a direct DR scenario in here. However, the general guidance is to define the expected RPO and RTO and see if the multi-region design is capable of supporting these requirements. **Note:**: RPO and RTO of Azure SQL DB have been explained in the the data platform design section
3. **Safe deployment**- The [Azure safe deployment practice (SDP) framework](https://azure.microsoft.com/blog/advancing-safe-deployment-practices) ensures that all code and configuration changes (planned maintenance) to the Azure platform undergo a phased rollout. 
4. **CDN, Edge-Caching** - It is a suggested practice to use the features of Content Delivery networks and edge caching if the workload is HTTP based and Application Delivery Network capabilities (i.e. accelerated delivery) are required. These are baked into Azure Front Door. This solution does not use AFD for reasons that would be elaborated in a separate section

### Constrained migrations via IaaS
This section from the documentation talks about the scenario where a workload has not been modernized yet, i.e. usage of containers or other cloud native technologies. We have taken such a scenario for our solution implementation where in the assumption is the web application runs on Virtual Machines on-premise. So the Azure based deployment stamps would also run the workload on Azure VMSS
#### Design Considerations and Recommendations
1. **Operational Costs of the VMs** - The operational costs of using IaaS virtual machines are significantly higher than the costs of using PaaS services because of the management requirements of the virtual machines and the operating systems. Managing virtual machines necessitates the frequent rollout of software packages and updates [**this is a direct excerpt from the documentation**]
2. **Availability of VMs** - To make sure the compute part of the workload is Highly Available, we have chosen the VMSS with autoscaling and the instances to be placed across the availability zones
3. **Right Sizing the VMs**- This is an important exercise to be performed when selecting the SKU of VMs that will be added to the Virtual Machine Scalesets. Azure provides a very nice tool that can simplify the job for you. The VM selection tool asks you a series of questions and then comes out with suggestions on the suitable SKUs of VMs. The output sheet from the exercise done for this solution is added [here](../Worksheets/VM-SelectionTool-OutputData.xlsx)
4. **Number of VMs for high-availability**- The general guidance is to have a minimum of 3 instances spread across the availability zones. However, in this use case, bursting to cloud has a default NFR to keep the cost low. This has been highlighted in the definition of "Burst to Cloud". So the design decision is to have just one instance in the VMSS by default and scale out by 2 instances every time a threshold is reached. 
5. **Scalability and Zone Redundancy**- VMSS in each of the Azure stamps will be created where the instances will be placed across availability zones. Scalilng will be automatic and will depend on an identified application performance threshold. The scale-out and scale-in actions need to be tested carefully so that the varying loads and sudden spikes are handled efficiently
6. **Use of load balancers** - this is a straight-forward design criteria and should be a no-brainer. We use an external load balancer that will receive the ingress traffic from the client in its public frontend IP address
7. **Use of standard Images**- The solution requires preparing a custom image and maintaining that as an Azure Managed Image or as an Image in the Compute Gallery. The reason for using a custom image is that the VM scale set uses the image to create a new instance every time it scales out. If the post VM creation script is heavy and is time consuming, then the scale-out operation would be delayed. To handle this issue, we will have the a)installation of IIS, creation of a Virtual directory and website and deploying of the stable version of the website done on a VM. We then sysprep the machine to prepare a golden image per region. This image is then used to create the VMSS. This process helps in briniging down the instance creation time during a scale-out by 300-400%
8. **Monitor virtual machines** - This has not been implemented to its entirety. We however do have provisions for the infrastructure logs from the scale set to be ingested into a regional log analytics workspace. The diagnostics settings need to be added.     

## 2. Data Platform Design
### Design Considerations and Recommendations
#### Volume
1. **Data Volume Growth** - The data storage requirements should be carefully assessed when deciding the storage sizing of Azure SQLDB or the size of the data disks if using SQL on Azure Virtual Machines. This becomes as important aspect of right-sizing the components to avoid issues related to data growth scenarios. The main metric that would help in deciding the volume of data growth would be the growth pattern in the past 'N' months. The data platform should be designed to accommodate an increase in the data storage needs. This requires over-provisioning Azure SQLDB with a considerable buffer of storage space. This may sound like counter-intuitive after having adopted the cloud which favors the "Use on demand model". As opposed to provisioning additional storage space, an automation mechanism can be setup to scale-up the storage capacity on-demand. This automation script can be executed in response to an alert that indicates exhaustion of 70% of the available space.  
*References*  
[Changing Azure SQLDB Storage Size](https://learn.microsoft.com/en-us/azure/azure-sql/database/single-database-scale?view=azuresql#change-storage-size)  
[Using Powershell to Increase the Size of an Azure SQLDB](https://learn.microsoft.com/en-us/powershell/module/az.sql/set-azsqldatabase?view=azps-9.7.0#example-3-modify-the-storage-max-size-of-a-database)  
[Imapact of Scaling Azure SQL resources up/down](https://learn.microsoft.com/en-us/azure/azure-sql/database/scale-resources?view=azuresql#impact-of-scale-up-or-scale-down-operations)  
2. **Removal or Offloading of older data**- This has not been implemented in this solution. The suggestion however is to have the data that will not be used and has not been for a very long time moved to a cold storage. Backup of the Azure SQLDB databases can be a good starting point. Unused databases, and old records from databases that are in use can be good candidates for further analysis
#### Velocity  
1. Support for High-Throughput- The data platform service chosen should be examined carefully for the throughput capabilities. In this solution, the Business Critical Service Tier has been chosen to handle this and a few other critical requirement of Mission-Critical workloads. The following excerpt from the [documentation](https://learn.microsoft.com/en-us/azure/azure-sql/database/service-tiers-sql-database-vcore?view=azuresql#service-tiers) talks about the IOPS offered by the Business Critical Service tier  

| Use case | General Purpose     | Business Critical                              | Hyperscale                                                                                                                                                |
| -------- | ------------------- | ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IOPS     | 16,000 maximum IOPS | **8,000 IOPS per vCore with 200,000 maximum IOPS** | 327,680 IOPS with max local SSD<br>Hyperscale is a multi-tiered architecture with caching at multiple levels. Effective IOPS will depend on the workload. |  

The key reasons why you should choose Business Critical service tier instead of General Purpose tier are:
**Low I/O latency requirements** – workloads that need a consistently fast response from the storage layer (1-2 milliseconds in average) should use Business Critical tier.  
If hosting the SQL database on Azure Virtual Machines (which would have been the actual design for an as-is scenario), the disk has to be chosen accordingly so as to handle the IO, Throughput and Latency requirements. Refer to the resources in this section to understand this better - https://github.com/gsriramit/AzureInfra-Disks#choosing-an-azure-disk---decision-tree-approach. The other important consideration would be choosing the right disk size (after choosing a "Premium SSD") so that the data layer does not experience the issues of *Disk IO Capping* or *VM IO Capping*. Read this article to understand this in-depth- https://learn.microsoft.com/en-us/azure/virtual-machines/disks-performance#disk-io-capping  
![image](https://user-images.githubusercontent.com/13979783/236624298-98daf74b-401c-440a-be29-7d68b9be9a24.png)  

   - **Support for Read and Write Context based throughput** - The system should be able to meet the throughput requirements of the read and write workloads appropriately. This becomes a hard requirement in multiple scenarios a) When we want the read requests to not use the processing time and resources of the master node b) the read requests are propotionately large and would still need to meet the P90/P95 latency requirements c) the same database also needs to support some minimal to moderate analytical operations, although the DB sharing is not the best practice. Only the first 2 of the above mentioned requirements are applicable to this solution.
The primary region comes with 3 read replicas that are capable of handling the read requests. The application has to be coded with the **"application-intent=read-only"** so that the read requests are handled by the read replicas. Also, when a burst happens to the secondary region, the geo-replica of the Azure SQL Db would be handling the read requests. Only the write requests would be sent to the Master node in the primary region
2. **Support for Highly Volatile workloads or requests patterns** - The suggestion here is to over-provision the database system to be able to accommodate the varying load levels. This has been disucssed in the previous section (Volume) as well. This solution suggests understanding the request pattern of the application and creating a SKU of Azure SQLDB based on the peaks rather than the troughs
3. **Support for auto-scaling** - This also has been discussed in the previous section
4. **Support for Caching** - The usual design of system that involves a read-heavy pattern is to have a layer of *external cache* in front of the database. This is done for reasons relating to performance (read from memory would always be faster than a read from the disk), DB read request offload for data that does not change much. The architecture would then have a Redis Cache placed in front of the Azure SQL DB and have the application programmed correctly to read from the cache during all the applicable scenarios. Implementation of caching is a fairly complex topic by itself and requires extensive design accuracy.  
Additional References:  
     - **Caching Strategies** - https://medium.com/datadriveninvestor/all-things-caching-use-cases-benefits-strategies-choosing-a-caching-technology-exploring-fa6c1f2e93aa
     - **Reference Implementation of a Caching Strategy in a .Net Applicaiton** - https://github.com/gsriramit/CachingStrategies  
5. **Monitoring Data read and write throughput  against the P90/P95 latency requirements** - This has not been implemented in this solution. However, the metrics from Aure SQL DB should be ingested into the targeted log analytics workspace and further analyzed to understand the performance of the data platform for varied throughput scenarios.  
   - **Query Performance Insights** - https://learn.microsoft.com/en-us/azure/azure-sql/database/query-performance-insight-use?view=azuresql#view-individual-query-details. This documentation provides the features available in the platform to understand the details of each of the executed queries. The "duration" data should be used to underdstand if the data platform is able to meet the throughout and the latency requirements at once. 
#### Veracity
1. **Support for a multi-region data platform design** - This solution uses Azure SQLDB Geo-Replicas to have the database distributed across 2 regions. This helps in ensuring maximum reliability, availability, and performance.
     - **Data replicas across Availability Zones (AZs)** Zone-redundancy feature of the Gen5 tier has been used to maximize intra-region availability.
2. **Support for Multi-region write** - As SQL is a single-master database, the solution does not support multi-region write requirements
3. **BCDR** - This solution does not include an implementation for backup & restore and the fail-over scenarios. However, these design and architecture are pretty much compatible with the common BCDR measures available for Azure SQLDB.
4. **Performance Benchmarks** - The performance benchmarks of the application as a whole involves doing load and stress testing against the app and observing the performance of the same. The data platform however needs to be tested separately. The following article has reference to tools that can be used to benchmark disks for throughput
     - **Disk Benchmarking**- https://learn.microsoft.com/en-us/azure/virtual-machines/disks-benchmarks  
     - **Benchmarking SQL Server and Azure SQL with WorkloadTools** -  https://learn.microsoft.com/en-us/shows/data-exposed/benchmarking-sql-server-and-azure-sql-with-workloadtools
5. **Encryption of Data** - This solution uses the platform-managed encryption keys to encrypt data at rest. If the solution needs to be extended to use Customer-Managed keys, then the keys need to be imported into Azure Keyvault and then used with Azure SQL Database.  

### Additional Design Considerations
#### 1. Data Platform High-Availability
**1.1 High Availability Design of SQL on Azure VMs and Hybrid Setups**
According to the actual design of using SQL on Virtual Machines, the on-premises would have had SQL installed in more than 1 machine to form an **Always-On Availability Group**. The SQL instances would have read replicas in addition to the one master/write replica, to handle the read requests. Also the always-on availability group provides regional resiliency where in one of the read replicas will be promoted as the master if the existing master node fails. This is a process of fail-over that happens within the ring of the availability group that makes it highly available. To further enhance the availability, when a multi-region application deployment approach is used, the Availability group will be extended from on-premises to Azure. The following diagram from the documentation illustrates the architecture of an always-on AG extended to a secondary Azure region. The concept is quite similar for a hybrid deployment wherein the on-premises and Azure networks are connected through an Azure Express Route Connection. **Note:** A VPN connection between the networks would not be ideal for a Mission-Critical workload as this would cause additional latencies when cross-region traffic needs to be handled.  
**Reference:** https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/availability-group-manually-configure-multi-subnet-multiple-regions?view=azuresql

![image](https://user-images.githubusercontent.com/13979783/236625109-8e8d612c-2296-4073-ac07-4c946b26475f.png)  
**1.2 High Availability Design of Azure SQL DB**
When using Azure SQL DB, the Business Critical SKU offers the necessary high availability feature by default. A SQL Database created in a Business Critical Server will be created with an **Always-on availability Group** with one master instance and 3 read replicas created in the ring. The following diagram illustrates the same. Another key aspect that needs to be noticed is that the Business Critical SKU comes with the locally attached storage disks to handle very low latency requirements. This necessarily does not fit into the HA features, but this is an important feature for mission-critical workloads with very low latency tolerance.  
Excerpt from the MS documentation
There are three high availability architectural models:  
- **Remote storage model** that is based on a separation of compute and storage. It relies on the high availability and reliability of the remote storage tier. This architecture targets budget-oriented business applications that can tolerate some performance degradation during maintenance activities.
- **Local storage model** that is based on a cluster of database engine processes. It relies on the fact that there is **always a quorum of available database engine nodes. This architecture targets mission-critical applications with high IO performance, high transaction rate and guarantees minimal performance impact** to your workload during maintenance activities.
- **Hyperscale model** which uses a distributed system of highly available components such as compute nodes, page servers, log service, and persistent storage. Each component supporting a Hyperscale database provides its own redundancy and resiliency to failures. Compute nodes, page servers, and log service run on Azure Service Fabric, which controls health of each component and performs failovers to available healthy nodes as necessary. Persistent storage uses Azure Storage with its native high availability and redundancy capabilities. To learn more, see Hyperscale architecture.  
The following table shows the availability options based on service tiers:  

| Service tier              | High availability model | Locally-redundant availability | Zone-redundant availability |
| ------------------------- | ----------------------- | ------------------------------ | --------------------------- |
| General purpose (vCore)   | Remote storage          | Yes                            | Yes                         |
| **Business Critical (vCore)** | **Local storage**           | **Yes**                            | **Yes**                         |
| Hyperscale (vCore)        | Hyperscale              | Yes                            | Yes                         |
| Basic (DTU)               | Remote storage          | Yes                            | No                          |
| Standard (DTU)            | Remote storage          | Yes                            | No                          |
| Premium (DTU)             | Local storage           | Yes                            | Yes                         |  

The following diagram shows the Always-On Availability group feature built into the Premium and Business Critical SKUs  
**Reference:**https://learn.microsoft.com/en-us/azure/azure-sql/database/high-availability-sla?view=azuresql&tabs=azure-powershell#premium-and-business-critical-service-tier-locally-redundant-availability
![image](https://user-images.githubusercontent.com/13979783/236626204-d99bd243-5335-4ed0-be93-3df250c78a78.png)

**1.2.1 Extending Azure SQLDB to Multiple Regions**
In comparison to the architecture depicted in section#1.1, Azure SQLDB being a managed service offers a feature called **Active Geo-replication**. Following is an excerpt from the MS documentation
*Active geo-replication leverages the **Always On availability group technology to asynchronously replicate transaction log generated on the primary replica to all geo-replicas**. While at any given point, a secondary database might be slightly behind the primary database, the data on a secondary is guaranteed to be transactionally consistent. In other words, changes made by uncommitted transactions are not visible.*  
**Multiple readable geo-secondaries**  
Up to *four geo-secondaries can be created for a primary*. If there is only one secondary, and it fails, the application is exposed to higher risk until a new secondary is created. If multiple secondaries exist, the application remains protected even if one of the secondaries fails. Additional secondaries can also be used to scale out read-only workloads.  
**Reference:**https://learn.microsoft.com/en-us/azure/azure-sql/database/active-geo-replication-overview?view=azuresql  

**Availability SLO, RPO and RTO of Azure SQLDB Business Critical Servers**  
- Azure SQL Database offers a baseline 99.99% availability SLA across all of its service tiers, but provides a higher **99.995% SLA for the Business Critical or Premium tiers in regions that support availability zones**.
- Azure SQL Database Business Critical or Premium tiers not configured for Zone Redundant Deployments have an availability SLA of 99.99%. When configured with geo-replication, the Azure SQL Database Business Critical tier provides a **Recovery Time Objective (RTO) of 30 seconds for 100% of deployed hours**.
- When configured with geo-replication, the Azure SQL Database Business Critical tier has a **Recovery point Objective (RPO) of 5 seconds for 100% of deployed hours**.
- **Reference**:https://learn.microsoft.com/en-us/azure/well-architected/mission-critical/mission-critical-data-platform#design-considerations-2  

## 3. Networking and Connectivity
### Design Considerations and Recommendations
#### Global Traffic Routing
1. According to the decision tree approach in choosing a global load balancer, for a HTTP based application, Azure Front Door would be the perfect fit. This implementation might be modified later to conform to the design recommendation. Please Note: The concept of handling the burst of traffic on Azure does not vary between Azure Front Door and Traffic Manager as both these services support weighted traffic routing and Azure Logic app can update the weights of the backend origins if AFD has been used. **Reference:** https://learn.microsoft.com/en-us/azure/frontdoor/routing-methods#weighted-traffic-routing-method 

####  Regional Load Balancing
1. The choice of the regional balancer should be an application gateway with the web application firewall so as the handle the L7 routing requirements (if any). WAF can provide the intended security at L7. This will be discussed in detail in the "Security" Design Area. Also, if WAF is associated with the Front Door profile, then the incoming traffic would have been examined for L7 vulnerabilities and having WAF with the application gateway might prove to be redundant and hence unnecessary
2. In this solution, we have selected a L4 public load balancer to receive the traffic at the regional level. *There is no specific reason behind this design decision*. The only consideration is that the load balancer, be it an app gateway or a Azure load balancer has to have a public frontend as the Traffic Manager can work only with public endpoints. 
   - This is by design as the Traffic Manager does not participate in the actual routing of the data packets. The client would receive the FQDN of the endpoint that the Traffic Manager selects (based on the configured algorithm and also the health of the endpoint) and would make a direct connection to the endpoint over the internet.
3. An alternate design could be having the Azure Front door connect privately to an Internal Load Balancer (ILB) through its support for Private Link. With this option, the traffic from the end user would be routed through the MS backbone network from the POP of FrontDoor. This becomes the preferred design for customers that require very high network security and cannot afford to expose the stamp endpoints to the internet directly
4. **Note:** 
     - The support for Azure FrontDoor privately connecting to an Azure Application Gateway is still not supported. So a trade off has to be made between the requirements of having the private connectivity to the endpoint and the multitude of uses of a regional L7 LB.
     - If this design decision is to be taken, the web application firewall can be placed in the FrontDoor so that the security scanning of the traffic would be done by the FrontDoor instance handling the traffic. Also the FrontDoor can compensate for the unavailability of the regional L7 LB for the path based routing by routing the traffic to the origin group based on the path. 
     - **Reference:** https://learn.microsoft.com/en-us/azure/frontdoor/front-door-route-matching?pivots=front-door-standard-premium#structure-of-a-front-door-route-configuration  

#### Other Design Considerations when using Azure Traffic Manager
Excerpt from the official MS documentation, applicable to this solution -
1. Use Traffic Manager for non HTTP/S scenarios as a replacement to Azure Front Door. **Capability differences will drive different design decisions for cache and WAF capabilities, and TLS certificate management**.
2. WAF capabilities should be considered within each region for the Traffic Manager ingress path, using Azure Application Gateway.
3. Configure a suitably low TTL value to optimize the time required to remove an unhealthy backend endpoint from circulation in the event that backend becomes unhealthy.
4. Similar to with Azure Front Door, a *custom TCP health endpoint* should be defined to validate critical downstream dependencies within a regional deployment stamp, which should be reflected in the response provided by health endpoints.
5. However, for Traffic Manager additional consideration should be given to service level regional fail over. such as 'dog legging', to mitigate the potential delay associated with the removal of an unhealthy backend due to dependency failures, particularly if it's not possible to set a low TTL for DNS records.
6. Consideration should be given to third-party CDN providers in order to achieve edge caching when using Azure Traffic Manager as a primary global routing service. Where edge WAF capabilities are also offered by the third-party service, consideration should be given to simplify the ingress path and potentially remove the need for Application Gateway.

#### Application Delivery Services
Refer to the official documentation for the design considerations and recommendations. This solution does not include App delivery services
https://learn.microsoft.com/en-us/azure/well-architected/mission-critical/mission-critical-networking-connectivity#application-delivery-services

#### Caching and Static Content Delivery Services
Refer to the official documentation for the design considerations and recommendations. This solution does not include Caching specific design and implementation
https://learn.microsoft.com/en-us/azure/well-architected/mission-critical/mission-critical-networking-connectivity#caching-and-static-content-delivery

#### Virtual Network Design
The Mission Critical guidelines advices against the interaction between the stamps in different regions as these are supposed to be independent units handling the regional traffic. This helps in lowering or avoiding  the impact of stamp in one reion by the failure of the components in the other. However
The reasons for the design decision have been discussed below. This solution however uses a connected VNET design for the following reasons  
1. SQL being a single master DB, **the traffic that bursts out to Azure from on-premises or the primary region will contain read and write requests**. When the secondary Azure stamp receives write requests, the same has to be sent to the master replica hosted in the primary DB server in the primary region. This connection to the private endpoint of the primary replica would be established through the global virtual network peerig between the regional networks
2. If Azure Front Door could have been used, the alternate design option could be identifying the read and write requests based on the URL and route the appropriate traffic between the on-premises/primary endpoint and the Azure/Secondary endpoint i.e the write requests to primary and read requests to the secondary. However, one aspect to be kept in mind is that **this method of partitioning the traffic might prove to be imbalanced**. This happens when there are mroe write requests that are recieved by the application even after bursting to Azure. This would again cause the primary endpoint to be overloaded and would defeat the purpose of using Azure to handle the spill-over traffic
3. **Note:** If the stamps are made independent, the asynchronous replication between the master/primary and secondary replica(s) in the secondary regions would happen over the MS backbone network and would not require the peering between the globalally separate networks  

#### Private Endpoints and Private DNS zones
1. The SQL server is each of the regions will be exposed only for private connections through Private Endpoints. The application running in the vmss will be using the private endpoints to connect to the SQL server and the database. 
2. The sample application in this solution does not use the Azure KeyVault to save and read the secrets and certificates. However, in the case of production grade implementations that use the keyvault, the same is exposes to the application only through private endpoints. KeyVault in this case is deployed as a regional resource, i.e. One per region that can be shared by all the stamps in the region (if more than one stamp needs to be brough up per region). The architecture diagram shows the keyvault as a resource scoped to the stamp for purposes of brevity.

**Private DNS zones** 
1. The DNS zone for Azure SQLDB (database.windows.net) will be deployed as a centralized resource in the global workload resource group. Private endpoint A records for the logical SQL servers from each of the regions would be added to the same DNS zone group. When the applications need to resolve the FQDN of the SQL server, they resolve the same by looking up the A records in the common Private DNS zone.  
2. **Note:** Even though a default requirement, it is worth a mention - the Virtual Network in every region should have the VNET link to the Private DNS zone so as be able to forward the address resolution requests accordingly. 
3. **Important Read:** 
     - There is a highly informative whitepaper that Adam Stuart has published on the design  criteria and approach for multi-region private DNS. The white paper can be read here - https://github.com/adstuart/azure-privatelink-multiregion   
     - When using Azure SQL Fail-over Groups as the mechanism for BCDR in a 2-region setup and with a single global Private DNS zone acting as the source of truth, the key takeaways are 
       - As mentioned in the previous section, the workload machines in the secondary region would resolve to the private IP of the SQL server in the first region when resolving the FQDN of the fail-over group. The traffic would then use the global VNET peering to send the requests to the primary region. This has been highlighted as a sub-optimal behavior associated with this design
       - When the fail-over happens to the secondary region, the FOG FQDN during the first step of the resolution would point to the FQDN of the SQL sever in the secondary region. This is by design of the fail-over group that it needs to maintain the information of the sever that serves as the master at any given point in time. 
       - After the FQDN of the secondary region's server is received, the same is resolved by doing a lookup in the global single private DNS zone  

![image](https://user-images.githubusercontent.com/13979783/236746024-72ece89c-ffec-4661-90a4-544ab2946e83.png)
**src**:https://www.youtube.com/watch?v=weZ-SPO-tIc&ab_channel=AdamStuart




 

