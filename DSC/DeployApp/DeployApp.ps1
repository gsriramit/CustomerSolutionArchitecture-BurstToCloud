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
        # Web request to download the application deployment package
        Invoke-WebRequest -Uri $using:WebDeployPackagePath -OutFile $Destination -Verbose
        # Get a reference to the path where the msdeploy.exe is located
        $MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select-Object -Last 1).GetValue("InstallPath")       
        # Set the current path to the where the msdeploy.exe is located
        Set-Location $MSDeployPath
        # run the msdeploy command to deploy the app
        .\msdeploy.exe -source:package="C:\WindowsAzure\WebApplication.zip" -dest:contentPath="CloudAppSite" -verb:sync
                
      }
    }
  }
}