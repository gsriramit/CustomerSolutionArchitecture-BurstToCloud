# parameters 
$region1_rg_stamp1 = "rg-r1stamp1-workload-dev01"
$region2_rg_stamp1 = "rg-r2stamp2-workload-dev02"
$region1_rg_monitoring = "rg-r1monitoring-dev01"
$region2_rg_monitoring = "rg-r2monitoring-dev02"
$global_rg_Name = "rg-global-dev01"
$tenantId="d787514b-d3f2-45ff-9bf1-971fb473fc85"
$subscriptionId= "695471ea-1fc3-42ee-a854-eab6c3009516"
$region1_location="eastus"
$region2_location="westus"
$global_rg_location="westus"


#login
Connect-AzAccount -Tenant $tenantId -Subscription $subscriptionId

# Create the resource groups for regional and global resources
New-AzResourceGroup -Location $region1_location -Name $region1_rg_stamp1
New-AzResourceGroup -Location $region1_location -Name $region1_rg_monitoring
New-AzResourceGroup -Location $region2_location -Name $region2_rg_stamp1
New-AzResourceGroup -Location $region2_location -Name $region2_rg_monitoring
New-AzResourceGroup -Location $global_rg_location -Name $global_rg_Name

## Deploy regional resources ##
# Region#1
# Deploy the stamp resources 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region1_rg_stamp1 `
-TemplateFile "..\DeploymentTemplates\Region1\Stamp\azuredeploy_region1_stamp1.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region1\Stamp\azuredeploy_region1_stamp1.parameters.json"
# Deploy the monitoring resources
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region1_rg_monitoring `
-TemplateFile "..\DeploymentTemplates\Region1\Observability\azuredeploy_region1_monitoring.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region1\Observability\azuredeploy_region1_monitoring.parameters.json"


# Region#2
# Deploy the stamp resources 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region2_rg_stamp1 `
-TemplateFile "..\DeploymentTemplates\Region2\Stamp\azuredeploy_region2_stamp1.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region2\Stamp\azuredeploy_region2_stamp1.parameters.json"
# Deploy the monitoring resources
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $region2_rg_monitoring `
-TemplateFile "..\DeploymentTemplates\Region2\Observability\azuredeploy_region2_monitoring.json" `
-TemplateParameterFile "..\DeploymentTemplates\Region2\Observability\azuredeploy_region2_monitoring.parameters.json"


## Deploy global resources ##
# Deploy Traffic Manager, Log Analytics workspace & Logic app
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.globalresources.json" `
-TemplateParameterFile "..\DeploymentTemplates\Global\WorkloadResources\azuredeploy.globalresources.parameters.json"
# Deploy the autoscale settings 
New-AzResourceGroupDeployment -Verbose -Force -ResourceGroupName $global_rg_Name `
-TemplateFile "..\DeploymentTemplates\Global\Automation\azuredeploy.autoscaleconfig.json" `
-TemplateParameterFile "..\DeploymentTemplates\Global\Automation\azuredeploy.autoscaleconfig.parameters.json"