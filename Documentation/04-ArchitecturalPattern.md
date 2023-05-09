# Architecture pattern for mission-critical workloads on Azure
*The following is an excerpt from the official documentation*  
This article presents a key pattern for mission-critical architectures on Azure. Apply this pattern when you start your design process, and then select components that are best suited for your business requirements. The article recommends a north star design approach and includes other examples with common technology components.We recommend that you evaluate the key design areas, define the critical user and system flows that use the underlying components, and develop a matrix of Azure resources and their configuration

## Core architecture pattern
The core architecture pattern that has been suggested for any workload that needs to be treated as Mission-Critical has the following characteristics  
1. The resources need to be identified and classified as Global and Regional resources
2. The Global and Regional resources have different characteristics and the same have been captured below (an excerpt from the documentation)
3. Each region can consist of one or more stamps and each stamp is supposed to be ephemeral - stamps should be created on-demand and should not affect the remaining resources present within the same region
   - The actual workload resources that serve the business functions are to be placed in the stamp resource group
4. The regional resources in additon to the stamp resources also have the supporting resources. The supporting regional resources take a different resource group as they are supposed to outlive the stamps and serve purposes common to all the stamps 
   - **Note:** The same kind of partitioning is applicable to the global resources too. The deployment templates in this solution have been created to adopt this pattern of resource creation  

![High Availability - MissionCritical-CoreArchitecture (1)](https://user-images.githubusercontent.com/13979783/237001149-1e22c964-81ea-4f19-9e6e-7dc3629126f4.png)

**src:Architecture derived from the base diagram - https://learn.microsoft.com/en-us/azure/well-architected/mission-critical/mission-critical-architecture-pattern#core-architecture-pattern **

**Note:** The rest of the documentation in this page are taken from the official MS documentation. 
### Global resources
Certain resources are globally shared by resources deployed within each region. Common examples are resources that are used to distribute traffic across multiple regions and monitoring resources for the application workload.

| Characteristic                 | Considerations                                                                                                                                                                                                                                                               |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Lifetime                       | These resources are expected to be long living (non-ephemeral). Their lifetime spans the life of the system or longer. Often the resources are managed with in-place data and control plane updates, assuming they support zero-downtime update operations.                  |
| State                          | Because these resources exist for at least the lifetime of the system, this layer is often responsible for storing global, geo-replicated state.                                                                                                                             |
| Reach                          | The resources should be globally distributed and replicated to the regions that host those resources. It’s recommended that these resources communicate with regional or other resources with low latency and the desired consistency.                                       |
| Dependencies                   | The resources should avoid dependencies on regional resources because their unavailability can be a cause for global failure. For example, certificates or secrets kept in a single vault could have global impact if there's a regional failure where the vault is located. |
| Scale limits                   | Often these resources are singleton instances in the system, and they should be able to scale such that they can handle throughput of the system as a whole.                                                                                                                 |
| Availability/disaster recovery | Regional and stamp resources can use global resources. It's critical that global resources are configured with high availability and disaster recovery for the health of the whole system.                                                                                   |  

### Regional stamp resources
The stamp contains the application and resources that participate in completing business transactions. A stamp typically corresponds to a deployment to an Azure region. Although a region can have more than one stamp.
| Characteristic                 | Considerations                                                                                                                                                                                                                                                                             |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Lifetime                       | The resources are expected to have a short life span (ephemeral) with the intent that they can get added and removed dynamically while regional resources outside the stamp continue to persist. The ephemeral nature is needed to provide more resiliency, scale, and proximity to users. |
| State                          | Because stamps are ephemeral and will be destroyed with each deployment, a stamp should be stateless as much as possible.                                                                                                                                                                  |
| Reach                          | Can communicate with regional and global resources. However, communication with other regions or other stamps should be avoided.                                                                                                                                                           |
| Dependencies                   | The stamp resources must be independent. They're expected to have regional and global dependencies but shouldn't rely on components in other stamps in the same or other regions.                                                                                                          |
| Scale limits                   | Throughput is established through testing. The throughput of the overall stamp is limited to the least performant resource. Stamp throughput needs to estimate the high-level of demand caused by a failover to another stamp.                                                             |
| Availability/disaster recovery | Because of the temporary nature of stamps, disaster recovery is done by redeploying the stamp. If resources are in an unhealthy state, the stamp, as a whole, can be destroyed and redeployed.                                                                                             |  

### Regional resources
A system can have resources that are deployed in region but outlive the stamp resources. For example, observability resources that monitor resources at the regional level, including the stamps.  
| Characteristic | Consideration                                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Lifetime       | The resources share the lifetime of the region and out live the stamp resources.                                                                       |
| State          | State stored in a region can't live beyond the lifetime of the region. If state needs to be shared across regions, consider using a global data store. |
| Reach          | The resources don't need to be globally distributed. Direct communication with other regions should be avoided at all cost.                            |
| Dependencies   | The resources can have dependencies on global resources, but not on stamp resources because stamps are meant to be short lived.                        |
| Scale limits   | Determine the scale limit of regional resources by combining all stamps within the region.                                                             |


