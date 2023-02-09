# Traffic Management -Burst To Cloud

## What is Cloud Bursting
In cloud computing, cloud bursting is a configuration that’s set up between a private cloud and a public cloud **to deal with peaks in IT demand. If an organization using a private cloud reaches 100 percent of its resource capacity, the overflow traffic is directed to a public cloud so there’s no interruption of services.**

In addition to flexibility and self-service functionality, the key advantage to cloud bursting is economical savings. **You only pay for the additional resources when there is a demand for those resources - no more spending on extra capacity you’re not using or trying to predict demand peaks and fluctuations**. An application can be applied to the private cloud, then burst to the public cloud only when necessary to meet peak demands. Plus, cloud bursting can also be used to shoulder processing burdens by moving basic applications to the public cloud to free up local resources for business-critical applications. When using cloud bursting, you should **consider security and compliance requirements, latency, load balancing, and platform compatibility**.  
src: https://azure.microsoft.com/en-us/resources/cloud-computing-dictionary/what-is-cloud-bursting/  

## Abstract of the Solution Implementation Plan
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
- Azure load testing tool needs to be used to exercise this scenario. Load pattern needs to be set in such a way that the burst happens to the cloud, continues to scale the scale-set beyond the first iteration and then slowly drop. At the end of the test, the traffic should be maintained at 80-90% of the Peak that on-premise can handle

## Design Considerations
1. The virtual machine scale sets deployed in region#1 will not have auto-scale configured. This mimics the on-premise environment where the infrastructure cannot be scaled out and that would be the main reason why a burst to cloud is considered
2. A **Baselining process** needs to be done to understand the peak performance of the 3 instance scale set deployed in region#1
   - The baselining process would help us understand 
     - The number of HTTP(s) requests/second that the on-prem set up can handle. The variables that need to be taken into account include  
       - The capacity of the virtual machines- General purpose machines from the D-series VMs should be sufficient for this setup
       - What is considered as the peak - From the metrics that appinsights provides, performanceCounters/requestExecutionTime (or) performanceCounters/requestExecutionTime should be the metric of interest. Based on the load test, if the performanceCounters/requestExecutionTime exceeds an assumed threshold of 1 second (or) performanceCounters/requestExecutionTime exceeds an assumed threshold of 2-3 per second, then the stamp set to be peaking its capacity. The request count in the load testing tool when this peaking happens indicates the point at which the on-premise set up would be just short of saturation. **Note:** if the assumed thresholds indicate 80% of the peaking point, then that would help in saving the stamp and bursting to the cloud before the stamp goes down
     - The load testing setup at the end of the baselining process gets us the number of execution engines required when the Virtual users (VUs) per engine instance is set to 250 i.e. in the JMX script file. This number needs to be reached for stamp#1 to peak
3. Region#2 will have just 1 instance in the scaleset depicting an Active Cold-StandBy setup for high availability
4. An external load balancer with an Azure provided DNS label has to be deployed in each of the 2 regions that will serve as the entry point for the regional traffic. 
5. Traffic manager has to be configured with just 2 endpoints that correspond to the stamps in the 2 regions, one representing the on-premise environment and the other representing the azure environment
6. Azure monitor autoscale rule has to be configured as follows
   - Rule: performanceCounters/requestExecutionTime > 1 second (threshold) for 2 minutes then 
     - *Scale out rule*: Increase the instance count by 2 (this would get this stamp to a state that is similar to stamp#1 i.e. 3 instances to handle the traffic)
     - b) *Automation Trigger rule*: change the weights of the traffic manager endpoints to 85 and 15 when scaleout operation is triggered and back to 100(stamp#1) and 0(stamp#2) when the scale-in operation is triggered 
     - c) *Cool down period*: the time that the autoscale engine needs to wait after the previous scaleout operation completed before scaling out again. This can be set to 3 minutes? 
     - d) *Scale in rule* : performanceCounters/requestExecutionTime < 900 ms

   
