# High Availability -Burst To Cloud

## What is Cloud Bursting
In cloud computing, cloud bursting is a configuration that’s set up between a private cloud and a public cloud **to deal with peaks in IT demand. If an organization using a private cloud reaches 100 percent of its resource capacity, the overflow traffic is directed to a public cloud so there’s no interruption of services.**  
In addition to flexibility and self-service functionality, the key advantage to cloud bursting is economical savings. **You only pay for the additional resources when there is a demand for those resources - no more spending on extra capacity you’re not using or trying to predict demand peaks and fluctuations**. An application can be applied to the private cloud, then burst to the public cloud only when necessary to meet peak demands. Plus, cloud bursting can also be used to shoulder processing burdens by moving basic applications to the public cloud to free up local resources for business-critical applications. When using cloud bursting, you should **consider security and compliance requirements, latency, load balancing, and platform compatibility**.  
src: https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-cloud-bursting/  

### Abstract of the Solution
The solution that has been implemented to demonstrate cloud bursting is a form of High-Availability Design that uses Azure as a destination for traffic that overflows or exceeds the processing capability of the on-premise setup. The advantages of this approach have been mentioned in the previous section. One key point about this solution is that Azure will not be a fail-over endpoint, rather it would run in a *hot-standby mode to scale out and scale in on demand*. To make repeatable deployments easy, we have selected a couple of Azure regions with one representing On-premise. The solution however can be applied to a proper hybrid setup as well. 

### Abstract of the Solution Implementation Plan
- Application: An asp.net application running on-premise is instrumented with application insights
- There is a hot stand-by setup on Azure.
-  This should be the same asp.net app made to run on VM scale sets that are initially created with just 1 instance. The cloud deployment would scale out when the on-premise is unable to handle the increase in the traffic
- The metrics of interest could be latency of the responses or anything that is indicative of the performance throttling of the instances on-premise
-  Traffic manager could be set up to use the weighted routing method with 99% weight assigned to the on-premise endpoint so that the on-premise endpoint would always be the one to handle the traffic and azure is used to handle burst-out traffic alone
- Implement a custom health check endpoint (/health) that is expected to return 200 or any of the acceptable response HTTP status codes. This makes sure that the Traffic manager continues to mark the on-premise endpoint healthy
- The traffic manager should start sending a portion of the traffic to the endpoint on Azure (app can be fronted by an app gateway or an external load balancer as this is a web-app) once **performance degradation** (Note: this would vary from one app to another and the methodology used in this implementation is for illustration purposes only) is observed in the app 
  - This configuration would require the weighted traffic routing configuration to be adjusted. E.g., Continue to send 90% to the on-premise endpoint and send 10% to azure
  - For this to happen, an automation mechanism has to be set up that will update the weights
- Azure Monitor auto-scale needs to be configured to scale-out and scale-in the cloud instances of VMSS based on the app metric that was configured for the application
  - The autoscale rule should also invoke a webhook that triggers the logic app that handles the update of Traffic manager. 
  - Note: 
      - If the load does not reduce, then the autoscale rule will continue to scale-out the vmss instances in the cloud stamp
      - When the load reduces, the autoscale rule should be able to scale the instances back in. This will stop when the metric is well within the limits of what can be handled by the on-premise infrastructure
- Azure load testing tool needs to be used to exercise this scenario. Load pattern needs to be set in such a way that the burst happens to the cloud, continues to scale the scale-set beyond the first iteration and then slowly drop. At the end of the test, the traffic should be maintained at 80-90% of the Peak that on-premise can handle

## Documentation Guide
The documentation of the solution will follow the pattern of the Microsoft Mission-Critical Workloads. Although the solution varies from the Mission Critical workloads in so many aspects, the Design sections will carry all the necessary information.  
1. Design Methodology - [Design Methodology]
2. Design Principles - [Design Principles]
3. Design Areas - [Design Areas]
4. Architectural Pattern - [Architectural Pattern]
5. Baseline Architecture - [Baseline Architecture]
   
## References
1. https://learn.microsoft.com/en-us/azure/load-testing/concept-load-testing-concepts
2. https://learn.microsoft.com/en-us/azure/load-testing/quickstart-create-and-run-load-test
3. https://learn.microsoft.com/en-us/azure/load-testing/how-to-high-scale-load
4. https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.network
5. https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.network/traffic-manager-webapp/azuredeploy.json
6. https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.network/traffic-manager-vm/azuredeploy.json
