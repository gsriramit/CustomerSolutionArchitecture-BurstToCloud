# Traffic Management -Burst To Cloud

## What is Cloud Bursting
In cloud computing, cloud bursting is a configuration that’s set up between a private cloud and a public cloud **to deal with peaks in IT demand. If an organization using a private cloud reaches 100 percent of its resource capacity, the overflow traffic is directed to a public cloud so there’s no interruption of services.**

In addition to flexibility and self-service functionality, the key advantage to cloud bursting is economical savings. **You only pay for the additional resources when there is a demand for those resources - no more spending on extra capacity you’re not using or trying to predict demand peaks and fluctuations**. An application can be applied to the private cloud, then burst to the public cloud only when necessary to meet peak demands. Plus, cloud bursting can also be used to shoulder processing burdens by moving basic applications to the public cloud to free up local resources for business-critical applications. When using cloud bursting, you should **consider security and compliance requirements, latency, load balancing, and platform compatibility**.  
src: https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-cloud-bursting/  

## Abstract of the Solution Implemenetation Plan
- Example: An asp.net application running on-premise is instrumented with application insights
  - https://learn.microsoft.com/en-us/samples/azure/azure-quickstart-templates/vmss-windows-webapp-dsc-autoscale/
- There is a cold stand-by setup on Azure.
-  This should be the same asp.net app made to run on VM scale sets that are initially created with just 1 instance. The cloud deployment would scale out when the on-premise is unable to handle the rise in traffic
- The metrics of interest could be latency of the responses or anything that is indicative of the performance throttling of the instances on-premise
  - https://learn.microsoft.com/en-us/rest/api/application-insights/metrics/get?tabs=HTTP
  - https://learn.microsoft.com/en-us/rest/api/application-insights/metrics/get?tabs=HTTP#metricid
-  Traffic manager could be set up to use the weighted routing method with 100% weight assigned to the on-premise endpoint so that the on-premise endpoint would always be the one to handle the traffic and azure is used to handle burst-out scenarios alone
- Implement a custom health check endpoint (/health) that is expected to return 200 or any of the acceptable response HTTP status codes. This makes sure that the Traffic manager continues to mark the on-premise endpoint healthy
- The traffic manager should start sending a portion of the traffic to the endpoint on Azure (app can be fronted by an app gateway or an ELB as this is a web-app) once performance degradation is observed in the app 
  - This configuration would require the weighted traffic routing configuration to be adjusted. Continue to send 90% to the on-premise endpoint and send 10% to azure
  - For this to happen, an automation mechanism has to be set up that will update the weights
- Azure Monitor auto-scale needs to be configured to scale-out and scale-in the cloud instances of VMSS based on the app metric that was configured for the application
  - https://learn.microsoft.com/en-us/azure/azure-monitor/autoscale/autoscale-overview#custom-metrics  
  - The autoscale rule should also invoke a webhook that triggers the logic app that handles the update of Azure Front Door or Traffic manager. 
  - https://github.com/Azure-Samples/azure-logic-app-traffic-update-samples
  - Note: 
      - If the load does not reduce, then the autoscale rule will continue to scale-out the vmss instances
      - When the load reduces, the autoscale rule should be able to scale the instances back in. This will stop when the metric is well within the limits of what can be handled by the on-premise infrastructure
- Azure load testing tool needs to be used to exercise this scenario. Load pattern needs to be set in such a way that the burst happens to the cloud, continues to scale the scale-set beyond the first iteration and then slowly drop. A the end of the test, the traffic should be maintained at 80-90% of the Peak that on-premise can handle
