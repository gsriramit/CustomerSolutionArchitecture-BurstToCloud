<#
    .SYNOPSIS
        Setup the prerequsites for a web server that rund the enterprise app
#>

Param ([string] $storageAccessToken,
[string] $deploymentPackageName)

#$WebDeployPackagePath = $Args[0]

# Force use of TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Configure Windows Firewall to allow HTTP traffic on port 8080
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=8080

# Install iis
Install-WindowsFeature web-server -IncludeManagementTools


$source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
$dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
Invoke-WebRequest -Uri $source -OutFile $dest
# Install the web deployment package
Start-Process -FilePath $dest -Wait -ArgumentList /passive
# Get a reference to the path where the msdeploy.exe is located
$MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")

# Set the version of the .net core hosting bundle
$NetCoreHostingBundlePath="C:\WindowsAzure\dotnet-hosting-6.0.14-win.exe"
# Web request to download the specific version of .net core hosting bundle
Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/321a2352-a7aa-492a-bd0d-491a963de7cc/6d17be7b07b8bc22db898db0ff37a5cc/dotnet-hosting-6.0.14-win.exe  -OutFile $NetCoreHostingBundlePath -Verbose
# Install the hosting bundle and restart the w3 service. This is a required step
Start-Process -FilePath $NetCoreHostingBundlePath -Wait -ArgumentList /passive
net stop was /y
net start w3svc

# Create a new directory where the app package contents would be extracted to 
New-Item C:\inetpub\wwwroot\CloudApp -type Directory
# Import the web-administration module
Import-Module webadministration
# This step is required before any IIS specific commands can be executed
Set-Location IIS:\Sites
# Create a new site within IIS to host the application
New-Item iis:\Sites\CloudAppSite -bindings @{protocol="http";bindingInformation=":8080:"} -physicalPath C:\inetpub\wwwroot\CloudApp

## This portion of the script deploys the application to IIS
# $Destination = "C:\WindowsAzure\WebApplication.zip"      
# $deploymentPackageBasePath= "https://stawebserverdeploy01.blob.core.windows.net/"
# $WebDeployPackagePath = $deploymentPackageBasePath + $deploymentPackageName
# Web request to download the application deployment package
# Invoke-WebRequest -Uri $WebDeployPackagePath -OutFile $Destination -Verbose
# Get a reference to the path where the msdeploy.exe is located
# $MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")       
# Set the current path to the where the msdeploy.exe is located
# Set-Location $MSDeployPath
# run the msdeploy command to deploy the app
# .\msdeploy.exe -source:package="C:\WindowsAzure\WebApplication.zip" -dest:contentPath="CloudAppSite" -verb:sync
