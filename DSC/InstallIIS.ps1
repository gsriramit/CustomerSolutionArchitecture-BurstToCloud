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
        $Destination = "C:\WindowsAzure\WebApplication.zip"
        $NetCoreHostingBundlePath="C:\WindowsAzure\dotnet-hosting-6.0.14-win.exe"
        Invoke-WebRequest -Uri $using:WebDeployPackagePath -OutFile $Destination -Verbose
        $Argument = '-source:package="C:\WindowsAzure\WebApplication.zip" -dest:auto,ComputerName="localhost", -verb:sync -allowUntrusted'
        $MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select -Last 1).GetValue("InstallPath")
        
        Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/321a2352-a7aa-492a-bd0d-491a963de7cc/6d17be7b07b8bc22db898db0ff37a5cc/dotnet-hosting-6.0.14-win.exe  -OutFile $NetCoreHostingBundlePath -Verbose
        Start-Process -FilePath $NetCoreHostingBundlePath -Wait -ArgumentList /passive
        net stop was /y
        net start w3svc

        New-Item C:\inetpub\wwwroot\CloudApp -type Directory
        Import-Module webadministration
        Set-Location IIS:\Sites
        New-Item iis:\Sites\CloudAppSite -bindings @{protocol="http";bindingInformation=":8080:CloudAppSite"} -physicalPath C:\inetpub\wwwroot\CloudApp

        Set-Location $MSDeployPath
        .\msdeploy.exe -source:package="C:\WindowsAzure\WebApplication.zip" -dest:contentPath="CloudAppSite" -verb:sync
        #Start-Process "$MSDeployPath\msdeploy.exe" $Argument -Verb runas 

        #To-Do upload a proper package to the storage account such that the files are directly within the webapplication folder. There should not be any nested folders
      }
    }
  }
}