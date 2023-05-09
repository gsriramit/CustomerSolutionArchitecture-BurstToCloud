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

![High Availability - MissionCritical-CoreArchitecture](https://user-images.githubusercontent.com/13979783/236999916-0c122926-fd33-42c3-91b7-51d58e152236.png)

**src:Architecture derived from the base diagram - https://learn.microsoft.com/en-us/azure/well-architected/mission-critical/mission-critical-architecture-pattern#core-architecture-pattern **
