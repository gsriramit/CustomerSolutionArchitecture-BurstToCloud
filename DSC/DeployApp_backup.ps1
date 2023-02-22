Configuration InstallIIS
# Configuration Main
{

  Param ( [string] $nodeName, $WebDeployPackagePath )

  Import-DscResource -ModuleName PSDesiredStateConfiguration

  Node $nodeName
  {
    WindowsFeature WebServerRole {
      Name   = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole {
      Name   = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService {
      Name   = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45 {
      Name   = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection {
      Name   = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging {
      Name   = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools {
      Name   = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor {
      Name   = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing {
      Name   = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication {
      Name   = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication {
      Name   = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization {
      Name   = "Web-AppInit"
      Ensure = "Present"
    }
    Script DownloadWebDeploy {
      TestScript = {
        Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
      }
      SetScript  = {
        $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
        $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        Invoke-WebRequest $source -OutFile $dest
      }
      GetScript  = { @{Result = "DownloadWebDeploy" } }
      DependsOn  = "[WindowsFeature]WebServerRole"
    }
    Package InstallWebDeploy {
      Ensure    = "Present"  
      Path      = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
      Name      = "Microsoft Web Deploy 3.6"
      ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
      Arguments = "ADDLOCAL=ALL"
      DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy {                    
      Name        = "WMSVC"
      StartupType = "Automatic"
      State       = "Running"
      DependsOn   = "[Package]InstallWebDeploy"
    }
    Script DeployWebPackage {
      GetScript  = {
        @{
          Result = ""
        }
      }
      TestScript = {
        $false
      }
      SetScript  = {


        ### Obsolete code (retained for reference)
        #$Argument = '-source:package="C:\WindowsAzure\WebApplication.zip" -dest:auto,ComputerName="localhost", -verb:sync -allowUntrusted'
        #Start-Process "$MSDeployPath\msdeploy.exe" $Argument -Verb runas 
        #####

        # Name and Path for the web application deployment package
        $Destination = "C:\WindowsAzure\WebApplication.zip"
        # Set the version of the .net core hosting bundle
        $NetCoreHostingBundlePath="C:\WindowsAzure\dotnet-hosting-6.0.14-win.exe"
        # Web request to download the application deployment package
        Invoke-WebRequest -Uri $using:WebDeployPackagePath -OutFile $Destination -Verbose
        # Get a reference to the path where the msdeploy.exe is located
        $MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")
        
        # Web request to download the specific version of .net core hosting bundle
        Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/321a2352-a7aa-492a-bd0d-491a963de7cc/6d17be7b07b8bc22db898db0ff37a5cc/dotnet-hosting-6.0.14-win.exe  -OutFile $NetCoreHostingBundlePath -Verbose
        # Install the hosting bundle and restart the w3 service. This is a required step
        Start-Process -FilePath $NetCoreHostingBundlePath -Wait -ArgumentList /passive
        net stop was /y
        net start w3svc

        # Add a Windows Defender Firewall rule to allow TCP connections on port 8080. If this is not done, then the VM instances will be rejecting 
        # the health probe and the actual traffic received from the Azure load balancer. This would happen even though port 8080 would be 
        # open at the application level i.e. a new site configured in the IIS with bindings to 8080
        netsh advfirewall firewall add rule name="TCP Port 8080" dir=in action=allow protocol=TCP localport=8080
        # Create a new directory where the app package contents would be extracted to 
        New-Item C:\inetpub\wwwroot\CloudApp -type Directory
        # Import the web-administration module
        Import-Module webadministration
        # This step is required before any IIS specific commands can be executed
        Set-Location IIS:\Sites
        # Create a new site within IIS to host the application
        New-Item iis:\Sites\CloudAppSite -bindings @{protocol="http";bindingInformation=":8080:CloudAppSite"} -physicalPath C:\inetpub\wwwroot\CloudApp

        # Set the current path to the where the msdeploy.exe is located
        Set-Location $MSDeployPath
        # run the msdeploy command to deploy the app
        .\msdeploy.exe -source:package="C:\WindowsAzure\WebApplication.zip" -dest:contentPath="CloudAppSite" -verb:sync
                
      }
    }
  }
}