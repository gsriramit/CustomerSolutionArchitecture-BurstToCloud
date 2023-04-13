# parameters 
$region1_rg_stamp1 = "rg-r1stamp1-workload-dev01"
$region2_rg_stamp1 = "rg-r2stamp2-workload-dev02"
$region1_rg_monitoring = "rg-r1monitoring-dev01"
$region2_rg_monitoring = "rg-r2monitoring-dev02"
$global_rg_Name = "rg-global-dev01"
$tenantId=""
$subscriptionId= ""
$region1_location="eastus"
$region2_location="southcentralus"
$global_rg_location="southcentralus"
$databasename = "svc-Todo-primaryDb"
$primaryServerName ="sqlserver-reg1st1-dev01" 
$secondaryServerName = "sqlserver-reg2st1-dev01" 
$databasePrivateDNSZone="privatelink.database.windows.net"

#login
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

# Create the resource groups for regional and global resources
New-AzResourceGroup -Location $region1_location -Name $region1_rg_stamp1
New-AzResourceGroup -Location $region1_location -Name $region1_rg_monitoring
New-AzResourceGroup -Location $region2_location -Name $region2_rg_stamp1
New-AzResourceGroup -Location $region2_location -Name $region2_rg_monitoring
New-AzResourceGroup -Location $global_rg_location -Name $global_rg_Name

## Deploy global resources - LA Workspace, Application Insights (for the monitoring of logic app) and Private DNS zone for SQL ##
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.globalresources.json" `
-TemplateParameterFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.globalresources.parameters.json"

## Deploy regional resources ##
# Region#1
# Deploy the monitoring resources
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region1_rg_monitoring `
-TemplateFile "..\DeploymentTemplates\Region1\Observability\azuredeploy_region1_monitoring.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region1\Observability\azuredeploy_region1_monitoring.parameters.json"
# Deploy the stamp resources 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region1_rg_stamp1 `
-TemplateFile "..\DeploymentTemplates\Region1\Stamp\azuredeploy_region1_stamp1.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region1\Stamp\azuredeploy_region1_stamp1.parameters.json"

# Region#2
# Deploy the monitoring resources
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region2_rg_monitoring `
-TemplateFile "..\DeploymentTemplates\Region2\Observability\azuredeploy_region2_monitoring.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region2\Observability\azuredeploy_region2_monitoring.parameters.json"
# Deploy the stamp resources 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region2_rg_stamp1 `
-TemplateFile "..\DeploymentTemplates\Region2\Stamp\azuredeploy_region2_stamp1.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region2\Stamp\azuredeploy_region2_stamp1.parameters.json"


# add the peering between the networks
# Get a reference to the on-premise virtual network.
$vnet1 = Get-AzVirtualNetwork -ResourceGroupName $region1_rg_stamp1 -Name 'primaryapvnet'
# Get a reference to the azure stamp virtual network.
$vnet2 = Get-AzVirtualNetwork -ResourceGroupName $region2_rg_stamp1 -Name 'secondaryvnet'
# Peer VNet1 to VNet2.
Add-AzVirtualNetworkPeering -Name 'LinkOnPremiseToAzure' -VirtualNetwork $vnet1 -RemoteVirtualNetworkId $vnet2.Id
# Peer VNet2 to VNet1.
Add-AzVirtualNetworkPeering -Name 'LinkAzureToOnPremise' -VirtualNetwork $vnet2 -RemoteVirtualNetworkId $vnet1.Id

# Install the Azure sql module if it does not exist
Install-Module Az.Sql

# Add the geo-replica of the database in the on-premise stamp
$database = Get-AzSqlDatabase -DatabaseName $databasename -ResourceGroupName $region1_rg_stamp1 -ServerName $primaryServerName
$database | New-AzSqlDatabaseSecondary -PartnerResourceGroupName $region2_rg_stamp1 -PartnerServerName $secondaryServerName -AllowConnections "All"

### A very important step ###
# the following sql script has to be run to create the ToDo table in the target database. 
# CreateToDoTable.sql
# options of running the script
# a) from the SQL Query explorer window (Azure portal) (OR)
# b) from SSMS after logging into any of the bastion hosts



## Deploy global resources ##
# Deploy Traffic Manager and the Virtual Network to Private DNS Zone links from both the regions
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.dependentglobalresources.json" `
-TemplateParameterFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.dependentglobalresources.parameters.json"

# Deploy the autoscale settings 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\Automation\azuredeploy.autoscaleconfig.json" `
-TemplateParameterFile "..\DeploymentTemplates\Global\Automation\azuredeploy.autoscaleconfig.parameters.json"

# Deploy the logic app that does the traffic management
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\Automation\azuredeploy.trafficMgmtLogicApp.json" 

# Create the action group that will get invoked from the alerts for cloud-burst and fallback are triggered
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\Automation\azuredeploy.actiongroup.json" 

# Create the application Insights Metric Alerts that will be triggered based on the configured request threshold conditions
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\Automation\azuredeploy.metricalert.json" 