# Design Methodology
## Design for Business Requirements
### 1. Select a Reliability Tier
The following table represents the Availability SLO (sometimes known as the uptime SLO) and the corresponding acceptable downtime associated with each of the SLO targets.As explained in the official documentation, the higher the availability SLO requirement, greater would be the design reliability criteria considered.
The product team should be involved in defining the availability SLO of the system. Once the same has been defined, then the cloud solution team needs to base their design decisions on this requirement. The targeted number cannot be achieved in the first cut of the design. The solution team needs to incrementally work on the design to get the SLO number to the intended level.  
**Further reading on Availability Targets of a Cloud System**
1. [Availability Targets of a System - Understanding SLI/SLO and SLA](https://ramsaztechbytes.wordpress.com/2021/10/11/learn-azure-well-architected-reliability-series-part1-1/)
2. [Customer Questionnaire- Gathering the specifics of availability requirements ](https://ramsaztechbytes.wordpress.com/2021/10/12/learn-azure-well-architected-reliability-series-part1-3/)
3. [Modeling Dependencies - How to model the dependencies that impact the availability of the system](https://ramsaztechbytes.wordpress.com/2021/10/13/learn-azure-well-architected-reliability-series-part1-7/)
4. [Composite SLO and SLA- Calculating the composite availability SLO](https://ramsaztechbytes.wordpress.com/2021/10/13/learn-azure-well-architected-reliability-series-part1-7/)  

| Reliability Tier (Availability SLO) | Permitted Downtime (Week) | Permitted Downtime (Month) | Permitted Downtime (Year)       |
|-------------------------------------|---------------------------|----------------------------|---------------------------------|
| 99.90%                              | 10 minutes, 4 seconds     | 43 minutes, 49 seconds     | 8 hours, 45 minutes, 56 seconds |
| 99.95%                              | 5 minutes, 2 seconds      | 21 minutes, 54 seconds     | 4 hours, 22 minutes, 58 seconds |
| 99.99%                              | 1 minutes                 | 4 minutes 22 seconds       | 52 minutes, 35 seconds          |
| 100.00%                             | 6 seconds                 | 26 seconds                 | 5 minutes, 15 seconds           |
| 100.00%                             | <1 second                 | 2 seconds                  | 31 seconds                      |

Reference to the [MS official SLA estimator tool](https://github.com/mspnp/samples/tree/master/Reliability/SLAEstimator)  
The most important highlight of the tool is that it picks the availability SLOs of the Azure services and uses them in a formula to caclulate the composite SLA of the system. **Note**: The SLO could vary based on the modelled **UserFlows**. However the design should be based on the principle of "The strength of the chain is equal to weakest link in the chain". Recalculate the SLO of the system after every major change in the design.  
The *Design Areas/Design Principles* page captures the *Availability SLO* of the system based on our design decisions

### 2. Design Principles and Design Areas
1. Design Principles - Microsoft's Well-Architected Framework (WAF) provides a prescriptive guidance to design & architect workloads on the cloud based on a set of proven best-practices . The Framework has guidance for design spanning across 5 major pillars i.e., Security, Reliability, Cost-Optimization, Operational Excellence and Performance Optimization. In this exercise, we will elaborate on the though-process that has gone into designing the solution based on the Well-Architected Framework  
[Reference to Design Principles](/Documentation/02-DesignPrinciples.md)
2. Design Areas - This section aims to capture the design decisions that have been taken to achieve the Business requirements while adhering to the Design Principles and Mission Critical standards  
[Reference to Design Areas](/Documentation/03-DesignAreas.md)

### 3. Mission Critical Baseline Architecture With Network Controls
The provided templates aim at deploying an application following the Mission-Critical baseline architecture with Network Controls. We also explain in the subsequent sections the areas in which the implementation differs from the baseline to address the customer requirements.  
[Reference to the Architecture Details Page]
