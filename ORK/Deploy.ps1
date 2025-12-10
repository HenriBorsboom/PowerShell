<# 	
 .NOTES

Copyright (c) 2014 Microsoft Corporation.
By using this script you accept the license agreement found within the Service Provider Operational Readiness Kit (ork.exe).
               	
File:		Deploy.ps1
	
Purpose:	Deployment script to automate a deployment exported from ORK
	
Pre-Reqs:	Windows Server 2012 R2, or Windows Server 2012 and Windows PowerShell 4.0	
				
Version: 	2.5.0.1230

Authors:	Rob Willis, Robert Larson, Joel Stidley, David McFarlane-Smith


 .SYNOPSIS
	Deployment script to automate PDT deployment exported from ORK
  
 .DESCRIPTION
	This script it used to start the PDT deployment process with all appropriate options. 
    It is intended to automate the setup and then execute the scripts required to complete the defined deployment.
	 		
 .EXAMPLE
	C:\PS>  .\Deploy.ps1
	
	Description
	-----------
	There are no options for Deploy.ps1, simply run it from the same folder where the customized Variable.xml, Workflow.xml, VMCreator.ps1, Installer.ps1, and any other files exported using ORK.

 .INPUTS
    None.

 .OUTPUTS
    None.

 .LINK
	http://aka.ms/ork
#>

  
#region - Global Script Variables
	$Script:Path = Get-Location
	$Script:ScriptLog = "$path\Deploy-" + (Get-Date -f yy.MM.dd-HH.mm.ss)  + ".log"
	$Script:CleanUp = "False"
	$ERRORLEVEL = -1
	$Host.UI.RawUI.WindowTitle = "Service Provider Operational Readiness Kit"
	$StartTime = Get-Date
	$Validate = $true
	$CurPath = Get-Location
	$VMCreatorPath = "$CurPath\VMCreator.ps1"

#endregion

#region - Script Functions
<#
 ==========================================================================================================	 
	Script Functions
		Get-IsElevated					- Checks if the script is in an elevated PS session
		Enable-PSModule					- Loads the Powershell Module Named
		Get-ConfigXML					- Loads Variable XML Variables	
		Get-Value						- Gets Variable Values
		Set-ScriptVariable				- Sets Script Variables
		Get-RegValue					- Gets Registry Values	
		New-ADClusterComputerObject     - Creates AD Cluster objects
		Check-HyperVInstallStatus		- Checks the status of Hyper-V on a specified host
		Get-VMSwitchInfo     			- Gets information about the VM Switches for current VM
		Test-PsRemoting                 - Tests to make sure current account has access to remote host
		Check-ClusteringRole			- Checks to see if failover clustering is installed, and install it if it isn't
		Enable-SharedVHDX				- Enables shared VHDX on a local drive temporarily.
		Wait-VM							- Waits for a specified VM to respond
		Add-ManagementTools				- Checks for and then installs the DNS and AD modules for PowerShell
		Add-HyperVPSTool				- Checks for and then installs the Hyper-V module for PowerShell
 ==========================================================================================================	
#>
function Get-IsElevated
{
	# Get the ID and security principal of the current user account
 	$WindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
 	$WindowsPrincipal=New-Object System.Security.Principal.WindowsPrincipal($WindowsID)
  
 	# Get the security principal for the Administrator role
 	$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 	# Check to see if currently running "as Administrator"
	if ($WindowsPrincipal.IsInRole($adminRole))
    {
    	return $True
    }
	else
    {
    	return $False
    }        
}

function Enable-PSModule
{
	[CmdletBinding()]
	PARAM
	(
		[string]$ModuleName
    )
	
	Write-Host -ForegroundColor 'Green' "Checking for $ModuleName PowerShell Module" 
	try
	{
		if (Get-Module -listavailable | Where-Object {$_.Name -eq "$ModuleName"}) 
		{
			Write-Host -ForegroundColor 'Green' "Attempting to load $ModuleName PowerShell Module..." 
			Import-Module $ModuleName -ErrorAction SilentlyContinue
			Write-Host -ForegroundColor 'Green' "$ModuleName PowerShell Module Loaded"
		}	
		else
		{
			Write-Host -ForegroundColor 'Red' "Can not find the $ModuleName PowerShell Module"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	catch [system.exception]
	{
		Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
		Stop-Transcript
		Exit $ERRORLEVEL
	}	
}	

function Get-ConfigXML
{
	[CmdletBinding()]
	PARAM
	(
		[string]$XMLFilePath
    )
	
	if (Test-Path "$XMLFilePath") 
	{
        try 
		{
			Write-Host " Loading Variable.xml... " -NoNewline
			$global:Variable = [XML](Get-Content "$XMLFilePath" -ErrorAction Stop)
			Write-Host -ForegroundColor 'Green' "Loaded"
			
			# Script Domain Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Administrator Domain Variables" 
			[string]$Script:Domain = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Domain
			[string]$Script:AdminUser = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Username
			[string]$Script:AdminPassword = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Password
						
			# Script Global Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Global Variables" 
			$Variable.Installer | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {
				Set-ScriptVariable -Name $_.Name -Value $_.Value
			}
			
			# Script Component Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Component Variables" 
			$Components = $Variable.Installer.Components.Component | ForEach-Object {$_.Name}
			$Components | ForEach-Object {
				$Component = $_
				$Variable.Installer.Components.Component | Where-Object {$_.Name -eq $Component} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -ne $null} | ForEach-Object {
					Set-ScriptVariable -Name $_.Name -Value $_.Value
				}
			}

			# Script Server Name and SQL Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Server Name and SQL Variables" 
			Write-Host ""
			$Roles = $Variable.Installer.Roles.Role | ForEach-Object {$_.Name}
			$Roles | ForEach-Object {
				$Role = $_
				$Variable.Installer.Roles.Role | Where-Object {$_.Name -eq $Role} | Where-Object {$_.Name -ne $null} | ForEach-Object {
					Set-ScriptVariable -Name $_.Name.Replace(" ","") -Value $_.Server
				}
				
				if ($_.Instance -ne $Null)
				{
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Instance") -Value $_.Instance
					$ServerX = $_.Server
					$InstanceX = $_.Instance
        
					if ($_.SQLCluster -ne "True") 
					{
						$SQLVersion = $Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Version}
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Version") -Value $SQLVersion
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLServiceAccount") -Value ($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value
						if (($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value -ne $null) 
						{
							Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value ($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value
						}
						else
						{
							Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value (Invoke-Expression (($Workflow.Installer.SQL.SQL | Where-Object {$_.Version -eq $SQLVersion} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value))
						}
						
						$SQLPort = $Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Port}
						if ($SQLPort -ne $null)
						{
							Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value $SQLPort
						}
						else
						{
							Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value "1433"
						}
					}
				}
				
				if ($_.SQLCluster -eq "True")
				{
					$ClusterX = $_.Server
					$Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Node} | Where-Object {$_.Preferred -eq "1"} | ForEach-Object {
						Set-ScriptVariable -Name $Role.Replace(" ","").Replace("Server","Node") -Value $_.Server
					}
				
					$SQLVersion = $Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Version}
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Version") -Value $SQLVersion
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLServiceAccount") -Value ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value
					$SQLSVCAccount = ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value

					if (($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value -ne $null) 
					{
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value
					}
					else
					{
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value (Invoke-Expression (($Workflow.Installer.SQL.SQL | Where-Object {$_.Version -eq $SQLVersion} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value))
					}
					
					$SQLPort = $Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Port}
					if ($SQLPort -ne $null)
					{
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value $SQLPort
					}
					else
					{
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value "1433"
					}
				}
			}
		
			if ($Variable.Installer.Roles.Role | Where-Object {($_.Name -eq $Role) -and ($_.Server -eq $Server)})
			{
				Set-ScriptVariable -Name $Role.Replace(" ","") -Value $Server
				Set-ScriptVariable -Name ($Role.Replace(" ","") + "Short") -Value $Server.Split(".")[0]
			}
		}
		catch [system.exception]
		{
			$Validate = $false
			Write-Host -ForegroundColor 'Red' "Failed to read XML File Definitions for $xmlFileName" 
			Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	else
	{
		$Validate = $false
		Write-Host -ForegroundColor 'Red' "Unable to locate $xmlFileName"
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}

function Get-Value
{
    [CmdletBinding()]
	PARAM
	(
		[string]$Value,
		[string]$Count
    )
	
	if ((Invoke-Expression ("`$Variable.Installer.VMs.VM | Where-Object {`$_.Count -eq `$Count} | ForEach-Object {`$_.$Value}")) -ne $null)
	{
        Invoke-Expression ("Return `$Variable.Installer.VMs.VM | Where-Object {`$_.Count -eq `$Count} | ForEach-Object {`$_.$Value}")
    }
	else
	{
        Invoke-Expression ("Return `$Variable.Installer.VMs.Default.$Value")
    }
}

function Set-ScriptVariable 
{
    [CmdletBinding()]
	PARAM
	(
		[string]$Name,
		[string]$Value
    )
	
	Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
    if (($Name.Contains("ServiceAccount")) -and !($Name.Contains("Password")) -and ($Value -ne "")) 
	{
        Invoke-Expression ("`$Script:" + $Name + "Domain = `"" + $Value.Split("\")[0] + "`"")
        Invoke-Expression ("`$Script:" + $Name + "Username = `"" + $Value.Split("\")[1] + "`"")
    }
}

function Get-RegValue
{
    [CmdletBinding()]
	PARAM
	(
		[string]$Server,
		[string]$Value
    )
	
	try
	{
		$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Server)
	}
	catch
	{
		$reg = $null
	}
	
    if ($reg -ne $Null)
	{
        $regKey= $reg.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Auto")           
        if ($regKey -ne $Null) 
		{
        	if ($regkey.GetValue($Value) -eq 1) 
			{
                return $True
            }
			else
			{
                return $False
            }
        }
    }
}

function New-ADClusterComputerObject 
{
	[CmdletBinding()]
	PARAM
	(
		[string]$Cluster,
		[string]$ClusterGroups,
		[string]$ClusterOU,
		[string]$TargetDC
    )
	
	Write-Host "  Creating Computer Object $Cluster"
	try
	{
		New-ADComputer -Name $Cluster -Path $ClusterOU -ErrorAction SilentlyContinue -Server $TargetDC
		
		$ClusterSID = $null
		While ($ClusterSID -eq $null)
		{
			try
			{
				$ClusterSID = (Get-ADComputer -Identity "$Cluster" -Server $TargetDC).SID
			}
			Catch 
			{
				Start-Sleep 1
			}
		}
		
		$nullGuid = New-Object Guid 00000000-0000-0000-0000-000000000000
		$ClusterGroups.Split(",") | ForEach-Object {
			Write-Host "  Creating Computer Object $_"
			New-ADComputer -Name $_ -Path $ClusterOU -ErrorAction SilentlyContinue -Server $TargetDC
        	$acl = $null
			While ($acl -eq $null)
			{
				try 
				{
					$acl = Get-ACL -Path "AD:CN=$_,$ClusterOU" -ErrorAction SilentlyContinue 
				} 
				catch 
				{
					Start-Sleep 1
				}
			}
		
			$ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $ClusterSID,"GenericAll","Allow","All",$nullGuid
			$acl.AddAccessRule($ace)
			Set-Acl -Path "AD:CN=$_,$ClusterOU" -AclObject $acl
		}
	    
		Disable-ADAccount -Identity "$Cluster$" -Server $TargetDC
	}
	catch [system.exception]
	{
		Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
	}		
}

# Verify Hyper-V is installed
function Check-HyperVInstallStatus
 {

	[CmdletBinding()]
	PARAM
	(
		[string]$CheckHost
    )

   
   Write-Host "    Hyper-V Configuration... " -NoNewline
   $HyperVRole = Get-WindowsFeature -ComputerName $CheckHost | Where-Object {$_.Name -eq 'Hyper-V'}
   
   If ($HyperVRole.Installed -ne "True") 
   {
    Write-Host "     Failed. Hyper-V is not installed." -ForegroundColor Red
    Write-Host "    Installing Hyper-V on $CheckHost. Complete configuration before continuing."
    Add-WindowsFeature Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart -ComputerName $CheckHost
    exit
	} else
	{
    Write-Host "Passed" -ForegroundColor Green
	}
}

function Get-VMSwitchInfo
{
	
	[CmdletBinding()]
	PARAM
	(
		[string]$VSwitch,
		[string]$HostServer
    )

    Write-Host "    Virtual Switch Configuration ($VSwitch)... " -NoNewline
 
    If (!(Get-VMSwitch -Name $VSwitch -ComputerName $HostServer -ErrorAction SilentlyContinue)) {
        Write-Host " Failed" -ForegroundColor Red
        Write-Host ""
        Write-Host "    Virtual switch $VMSwitch does not exist. You must create this virtual switch or update your configuration to continue" -ForegroundColor Red
        exit
        } Else {
         Write-Host "Passed" -ForegroundColor Green

   }

}

function Test-PsRemoting 
{ 
    param( 
        [Parameter(Mandatory = $true)] 
        $computername 
    ) 
     
	Write-Host "    PowerShell Remoting... " -NoNewline 
    
	try 
    { 
        $errorActionPreference = "Stop" 
        $result = Invoke-Command -ComputerName $computername { 1 } 
		if ($result)
		{
		 Write-Host "  Passed" -ForegroundColor Green
		 return $True
		}
	} 
    catch 
    { 
        Write-Host "  Failed" -foregroundColor Red
		Write-Verbose $_ 
        return $False 
    } 
     
    if($result -ne 1) 
    { 
        Write-Verbose "   Failed. Unexpected results returned." -ForegroundColor Red
        return $False 
    } 
     
}

function Exit-Script
{
	Write-Host "`nDeploy started at: $StartDate"
	$EndDate=Get-Date
	Write-Host "Deploy completed at: $EndDate"
	Write-Host "`nScript execution time in minutes:" 
	$TotalTime = $EndDate - $StartDate
	Write-Host $TotalTime.TotalMinutes
	Write-Host "======================================================================"
	Stop-Transcript
	exit
}

function Check-ClusteringRole
 {

	[CmdletBinding()]
	PARAM
	(
		[string]$CheckHost
    )

   
   Write-Host "    Failover Clustering Role... " -NoNewline
   $RoleStatus = Get-WindowsFeature -ComputerName $CheckHost | Where-Object {$_.Name -eq 'Failover-Clustering'}
   
   If ($RoleStatus.Installed -ne "True") 
   {
    Write-Host "Warning. Failover Clustering is not installed." -ForegroundColor Yellow
    Write-Host "     Installing Failover Clustering on $CheckHost." -ForegroundColor Yellow
    Add-WindowsFeature Failover-Clustering -IncludeAllSubFeature -IncludeManagementTools -ComputerName $CheckHost 
    return $False
	} else
	{
    Write-Host "Passed" -ForegroundColor Green
	return $True
	}
}

function Enable-SharedVHDX
{

[CmdletBinding()]
	PARAM
	(
		[string]$VMH,
		[string]$FilterDrive
    )
# Enable SVHDXFLT on the SharedVHDX Drive ----

	Write-Host "     Enabling the Shared VHDX Filter on $VMH for $FilterDrive"
	
	$sb = {FLTMC attach svhdxflt $Using:FilterDrive}

	Invoke-Command -ScriptBlock $sb -ComputerName $VMH -AsJob
						
	Write-Host "     You must manually attach the Shared VHDX Filter after each reboot using the following command:" -ForegroundColor Yellow
	Write-Host "       FLTMC attach svhdxflt $FilterDrive" -ForegroundColor Yellow

}

function Wait-VM
{
	PARAM
	(
		[string]$VMName,
		[string]$Domain
    )

	Write-Host "   Verifying access to $VMName"
	Write-Host "    Registry... " -NoNewline
    While (!(Get-RegValue -Server $VMName -Value $VMName))
	{
		Start-Sleep 1
	}
    Write-Host "Ready" -ForegroundColor Green    
	
	Write-Host "    DNS...      " -NoNewline
    While (!(Resolve-DNSName -Name "$VMName.$Domain" -ErrorAction SilentlyContinue))
	{
		Invoke-Command -ComputerName $VMName -ScriptBlock {ipconfig.exe /registerdns | Out-Null}
        Start-Sleep 15
	}
	Write-Host "Ready" -ForegroundColor Green
	Write-Host ""
}

function Add-ManagementTools
 {

	[CmdletBinding()]
	PARAM
	(
		[string]$CheckHost
    )

   # Check to make sure DNS tools are installed
   Write-Host
   Write-Host "   DNS Remote Server Administrator Tools Configuration... " -NoNewline
   $DNSRSATRole = Get-WindowsFeature -ComputerName $CheckHost | Where-Object {$_.Name -eq 'RSAT-DNS-Server'}
   
   If ($DNSRSATRole.Installed -ne "True") 
   {
    Write-Host "     Failed. DNS Remote Service Administration Tools are not installed." -ForegroundColor Yellow
    Write-Host "    Installing RSAT-DNS-Server on $CheckHost."
    Add-WindowsFeature RSAT-DNS-Server -IncludeAllSubFeature -IncludeManagementTools -ComputerName $CheckHost
    
	} else
	{
    Write-Host "Passed" -ForegroundColor Green
	}
	
	# Check to make sure the AD tools are installed
	Write-Host
	Write-Host "   Active Directory module for Windows PowerShell... " -NoNewline
   $ADDSRSATRole = Get-WindowsFeature -ComputerName $CheckHost | Where-Object {$_.Name -eq 'RSAT-AD-PowerShell'}
   
   If ($ADDSRSATRole.Installed -ne "True") 
   {
    Write-Host "     Failed. Active Directory module for Windows PowerShell is not installed." -ForegroundColor Yellow
    Write-Host "    Installing RSAT-AD-PowerShell on $CheckHost."
    Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -IncludeManagementTools -ComputerName $CheckHost
    
	} else
	{
    Write-Host "Passed" -ForegroundColor Green
	}
	
}

function Add-HyperVPSTools
 {

	[CmdletBinding()]
	PARAM
	(
		[string]$CheckHost
    )

   # Check to make sure Hyper-V PowerShell tools are installed
   Write-Host
   Write-Host "   Hyper-V module for Windows PowerShell Configuration... " -NoNewline
   $RSATRole = Get-WindowsFeature -ComputerName $CheckHost | Where-Object {$_.Name -eq 'Hyper-V-PowerShell'}
   
   If ($RSATRole.Installed -ne "True") 
   {
    Write-Host "     Failed. Hyper-V module for Windows PowerShell is not installed." -ForegroundColor Yellow
    Write-Host "    Installing Hyper-V-PowerShell on $CheckHost."
    Add-WindowsFeature Hyper-V-PowerShell -IncludeAllSubFeature -IncludeManagementTools -ComputerName $CheckHost
    
	} else
	{
    Write-Host "Passed" -ForegroundColor Green
	}
 
}

#endregion
 
#region - Script Control Routine
Start-Transcript $ScriptLog
Write-Host " ======================================================================"
$StartDate=Get-Date ; Write-Host "Deploy started at: $StartDate"

# Elevate
Write-Host " Checking for elevation... "
$CurrentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
if (($CurrentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) -eq $false)  {
    Write-Host "  Elevating"
    Start-Process powershell.exe -Verb RunAs -ArgumentList ($ArgumentList -f ($myinvocation.MyCommand.Definition))
    Exit
}
# Get Variable.XML content
Get-ConfigXML ".\Variable.XML"

$VMCount = $Variable.Installer.VMs.Count

# Check OS version
If ((Get-WmiObject -Class Win32_OperatingSystem).Version.Split(".")[2] -lt 9200) 
	{
    
		Write-Host " PDT should be run from Windows Server 2012 or later" -ForegroundColor Red
	}

Write-Host "  Verifying local configuration..."

# In some instances the host doing the deployment won't be a Hyper-V server. Need to check if Hyper-V module for PowerShell is loaded locally
Add-HyperVPSTools $Env:ComputerName
		  
# Check the VHD configuration for the VMs, if using differential disks, must make sure that the parent VHD is available.
Write-Host ""
Write-Host "  Verifying host configuration..."
Write-Host ""

# Build a list of all hosts being used
# This list is built separately because testing for and installing Hyper-V takes longer than the other steps.
$CheckedHost = @()
    For ($i = 1; $i -le $VMCount; $i++) 
	{
 		$VMHost = Get-Value -Count $i -Value "Host"
		$CheckedHost = $CheckedHost + $VMHost.ToUpper()
		$UniqueHosts = $CheckedHost | Sort-Object | Get-Unique
	}
	
# Now that we have a list of the unique hosts we can test for and then validate each host once.
# This way we do it once for each host.	
Foreach ($Unique in $UniqueHosts)
{
	Write-Host "   Host: $Unique"
		
	#Check to make sure we have access to this host.
	$TestResult = Test-PsRemoting $Unique
	If ($TestResult -eq $false)
	{
		Write-Host ""
		Write-Host "   Error contacting $Unique Verify the host is correct and that the current user has access." -ForegroundColor Red
		
		Exit-Script
		
		}
		# Check to see if Hyper-V is installed
		Check-HyperVInstallStatus $Unique

		Write-Host ""
}

 Write-Host "  Validating VM configuration..."
 
 # Loop through each VM and check the configuration.
  For ($i = 1; $i -le $VMCount; $i++) 
  {
  
      # Determine if the parent disk exists in the correct location
			$VMSwitch = Get-Value -Count $i -Value "NetworkAdapter.VirtualSwitch"
			$VMHost = Get-Value -Count $i -Value "Host"
			$OSDisk = Get-Value -Count $i -Value "OSDisk.Parent"
            
            # Check if the path is already UNC
            If ($OSDisk.Contains("\\"))
            {
                $OSDiskUNC = $OSDisk
            }
            Else
            {    
                    $OSDiskUNC = "\\" + $VMHost + "\" + $OSDisk.Replace(":","$")
            }
            
            $VMFolder = Get-Value -Count $i -Value "VMFolder"
            # Check if the path is already UNC
            If ($VMFolder.Contains("\\"))
            {
                $VMFolderUNC = $VMFolder
            }
            Else
            {
                $VMFolderUNC = "\\" + $VMHost + "\" + $VMFolder.Replace(":","$")
            }
            
            $VHDFolder = (Get-Value -Count $i -Value "VHDFolder") + "\" + $VMName + "\Virtual Hard Disks"
            # Check if the path is already UNC
            If ($VHDFolder.Contains("\\"))
            {
                $VHDFolderUNC = $VHDFolder
            }
            Else
            {
                $VHDFolderUNC = "\\" + $VMHost + "\" + $VHDFolder.Replace(":","$")
            }

            $OSVHDFormat = $OSDisk.Split(".")[$OSDisk.Split(".").Count - 1]

			$OSVHDFolder = $OSDisk.Substring(0,$OSDisk.LastIndexOf("\"))
            # Check if the path is already UNC
            If ($OSVHDFolder.Contains("\\"))
            {
                $OSVHDFolderUNC = $OSVHDFolder
            }
            Else
            {
                $OSVHDFolderUNC = $OSDiskUNC.Substring(0,$OSDiskUNC.LastIndexOf("\"))
            }

			$VMName = Get-Value -Count $i -Value "VMName"
    			
			# $OSDiskType = Get-Value -Count $i -Value "OSDisk.Type"
        	Write-Host ""		
            Write-Host "   VM$i - $VMName on $VMHost"
                        
            # Verify a virtual switch exists that matches the configuration.
			
			Get-VMSwitchInfo $VMSwitch $VMHost
		
			Write-Host "    VM Path $VMFolderUNC... " -NoNewLine
      		
			If (!(Test-Path $VMFolderUNC -PathType Container))
			{
				Try
				{
					$null = New-Item -Path $VMFolderUNC -Type Directory -ErrorAction Stop
					Write-Host "Created" -ForegroundColor Yellow
				}
				Catch
				{
					Write-Host "Failed" -ForegroundColor Red
					Write-Host "   Unable to create VM Folder: $VMFolderUNC. Please correct before continuing." -ForegroundColor Red
					Exit-Script
				}
			}
			Else
			{
				Write-Host "Passed" -ForegroundColor Green
			}

			Write-Host "    VHD Path $OSDiskUNC... " -NoNewLine
            $sourcePath = $Variable.Installer.Variable | Where-Object {$_.Name -like "Download"}
			
            $VHDCopySourceVHD = $sourcePath.Value.ToString() + "\" + $OSDisk.Split("\")[$OSDisk.Split("\").Count - 1]
     
			# Try to copy the disk if it does not exist
                If (!(Test-Path $OSDiskUNC)) {   
                    Write-Host "     OS parent disk $OSDisk does not exist." 
                   
					# Verify that the source disk exists.
                    If (test-path $VHDCopySourceVHD) {

                        Write-Host "     Copying $VHDCopySourceVHD to $OSDiskUNC"

                        # If the folder doesn't exist create it
                        $null = New-Item -Path $OSVHDFolderUNC -ItemType Directory
						
						# Copy the VHD
                        Copy-item -Path $VHDCopySourceVHD -Destination $OSDiskUNC

                    } Else {
                    Write-Host "     Source VHD $VHDCopySourceVHD does not exist in the source folder. Please correct before continuing." -ForegroundColor Red
                    Exit
                    }
                } Else {
                
                $SourceFileProp = Get-ItemProperty $VHDCopySourceVHD
                $DestFileProp = Get-ItemProperty $OSDiskUNC
               
                If ($SourceFileProp.Length -ne $DestFileProp.Length)
                {
					Write-Host "     Warning" -ForegroundColor Yellow
					Write-Host "     Existing file size is different than source file." -ForegroundColor Red
					Write-Host "     Copying $VHDCopySourceVHD to $OSDiskUNC"
					$null = Copy-item -Path $VHDCopySourceVHD -Destination $OSDiskUNC -Force
                }
                
				Write-Host "Passed" -ForegroundColor Green
				
            }  
    
			#region SharedDisks Check if the VM has Shared VHDX files and verify the configuration.
	        $SharedDataDisks = Get-Value -Count $i -Value "SharedDataDisks"
                
            If (($SharedDataDisks -ne $null) -and ($SharedDataDisks -ne "")) 
			{
                $SharedVHDXFolder = Get-Value -Count $i -Value "SharedVHDXFolder"
				$SharedVHDXDrive = $SharedVHDXFolder.Substring(0,1)
				$SharedVHDXDisk = $SharedVHDXFolder.Substring(0,2)		
				
				# Check to see if there is a drive letter assigned
				If($SharedVHDXDrive -match '\w')
				{
					# Check to see if clustering is install on host for this VM and go ahead and install it, if not.
					$IsRoleInstalled = Check-ClusteringRole $VMHost
					
					# If clustering was not installed, throw a warning that this might not work out if using multiple hosts.
					If ($IsRoleInstalled -eq $false)
					{
						# If we are deploying to multiple hosts, this may break shared VHDX
						If($UniqueHosts.Count -gt 1)
						{
							Write-Host "     $VMHost is not part of a failover cluster. If not using a cluster virtual machines using Shared VHDX storage should be placed on the same host." -ForegroundColor Yellow
						}

						Enable-SharedVHDX -VMH $VMHost -FilterDrive $SharedVHDXDisk
						
					}
					Else
					{
						$ClusterService = Get-Service -ComputerName $VMHost | Where-Object {$_.Name -eq "ClusSvc"}
						
						# If the cluster service is stopped, then there will be no current CSV
						If ($ClusterService.Status -eq "Stopped")
						{
							Enable-SharedVHDX -VMH $VMHost -FilterDrive $SharedVHDXDisk
						}
						ElseIf ($ClusterService.Status -eq "Running")
						{
							# If there is already a Shared Volume, we don't want to enable the filter
							$ClusteredSharedVolumes = Invoke-Command -ComputerName $VMHost -ScriptBlock {Get-ClusterSharedVolume}
							
							If ($ClusteredSharedVolumes -eq $null)
							{
								
								Enable-SharedVHDX -VMH $VMHost -FilterDrive $SharedVHDXDisk

							}
							ElseIf ($ClusteredSharedVolumes.Count -gt 0)
							{
								Write-Host "    Shared VHDX Volume Available."
							}
												
						}
						Else
						{
							Write-Host "     $VMHost in an unknown state. Shared VHDX may not work" -ForegroundColor Red					
						}
					
					}
							
					# Make sure the Shared VHDX Folder exists. If it doesn't go ahead and create it.
					$SharedVHDXFolderUNC = "\\" + $VMHost + "\" + $SharedVHDXFolder.Replace(":","$")
					If (!(Test-Path $SharedVHDXFolderUNC))
					{   
						Write-Host "       Shared VHDX Path $SharedVHDXFolderUNC does not exist." 
						Write-Host "       Creating $SharedVHDXFolderUNC" 
				        $null = New-Item -Path $SharedVHDXFolderUNC -ItemType Directory -ErrorAction Ignore
					}
				} 
				elseif($SharedVHDXDrive -eq "`\") # Shared VHDX being stored on a file share
				{
					If ($Env:USERDNSDOMAIN -eq $null)
					{
						Write-Host "     $VMHost does not appear to be in a domain. Using SMB for storing VM data is unsupported." -ForegroundColor Red
										
					}
					
					Write-Host "     You are deploying a Shared VHDX on the following SMB share: $SharedVHDXFolder." -ForegroundColor Yellow
					Write-Host "      You must manually verify that this SMB share supports Shared VHDX." -ForegroundColor Yellow
									
					
					If (!(Test-Path $SharedVHDXFolder))
					{   
						Write-Host "     Shared VHDX Path $SharedVHDXFolder does not exist or the current user does not have access." 
						Write-Host "     Creating $SharedVHDXFolder" 
				        New-Item -Path $SharedVHDXFolder -ItemType Directory -ErrorAction Ignore
					}
					
				}
				else
				{
					Write-Host "     The Shared VHDX folder configuration did not validate." -ForegroundColor Red
					Exit-Script
				}
			}
			#endregion SharedDisks
        }
	
   	# Check to see if this is a new domain or not.
	$NewDomain = $Variable.Installer.VMs.Domain.Name
	$DomainExists = $Variable.Installer.VMs.Domain.Existing

	# If building a new domain
	
	If ($DomainExists.ToUpper() -eq "FALSE")
	{
		If (Test-Path $VMCreatorPath)
		{
			# Clear-Host
			Write-Host ""
			Write-Host ""
			Write-Host "  Running .\VMCreator.ps1 -Setup $CurPath" -ForegroundColor Green
			Write-Host ""
			# Start VMCreator
			.\VMCreator.ps1 -Setup $CurPath
		}
		else
		{ 
			Write-Host -ForegroundColor Red "  VMCreator.ps1 not found"
			Exit-Script
		}
		
		$DCName = Get-Value -Count 1 -Value "VMName"

		Write-Host ""
		Write-Host ""
		Write-Host "  To view the deployment progress, sign on to $DCName" -ForegroundColor Green
		Write-Host ""
		Write-Host "  If you experience issues, please see the Troubleshooting section of the Operational Readiness Kit Planning Guide."
 
		Exit-Script
	}
	ElseIf($DomainExists.ToUpper() -eq "TRUE")
	{
		Write-Host ""
		Write-Host "   Creating accounts and configuring Active Directory for deployment."
		Write-Host ""
		
		# Verify management tools are installed locally, because DomainPrep expects DNS and AD modules for PowerShell to be available
		Add-ManagementTools $Env:ComputerName
	
        # region - Run DomainPrep
		# Run DomainPrep to complete configuration.
		Write-Host "    Running .\DomainPrep.ps1 -Stage OUs -DisableLogging"
		Write-Host ""

		# DomainPrep has its own log. Pausing log here.
		#$null = Stop-Transcript
		# Running DomainPrep 
		.\DomainPrep.ps1 -Stage OUs -DisableLogging

		Write-Host "    Running .\DomainPrep.ps1 -Stage Accounts -DisableLogging"
		.\DomainPrep.ps1 -Stage Accounts -DisableLogging

		Write-Host "    Running .\DomainPrep.ps1 -Stage VMM -DisableLogging"
		.\DomainPrep.ps1 -Stage VMM -DisableLogging

		Write-Host "    Running .\DomainPrep.ps1 -Stage Clusters -DisableLogging"
		.\DomainPrep.ps1 -Stage Clusters -DisableLogging
		# Start transcript again
		#$null = Start-Transcript $ScriptLog -Append
		Write-Host ""
		# endregion - Run DomainPrep
        	
		# Run VMCreator
		If (Test-Path $VMCreatorPath)
		{
			# Clear-Host
			Write-Host ""
			Write-Host ""
			Write-Host "  Running .\VMCreator.ps1 -Setup $CurPath" -ForegroundColor Green
			Write-Host ""
			# Start VMCreator
			.\VMCreator.ps1 -Setup $CurPath
		}
		else
		{ 
			Write-Host -ForegroundColor Red "  VMCreator.ps1 not found"
			Exit-Script
		}
		
		Write-Host "  Waiting for all VMs to be available before deployment continues."
		Write-Host ""
	
		# region - Wait for VMs
		$Servers = @($Variable.Installer.Roles.Role | Where-Object {($_.Existing -ne "True") -and ($_.SQLCluster -ne "True")} | Sort-Object {$_.Server} -Unique | ForEach-Object {$_.Server})
	
		$Servers | Sort-Object -Unique | ForEach-Object {$VMName = $_.split(".")[0]     
		Wait-VM -VMName $VMName -Domain $NewDomain}
		Write-Host "" 
		# endregion - Wait for VMs

		# region - Run DomainPrep -Groups
		# Run DomainPrep to complete configuration.
		Write-Host "    Running .\DomainPrep.ps1 -Stage Groups -DisableLogging"
		Write-Host ""
		# DomainPrep has its own log. Pausing log here.
		#$null = Stop-Transcript
		# Running DomainPrep 
		.\DomainPrep.ps1 -Stage Groups -DisableLogging
    	Write-Host "    Running .\DomainPrep.ps1 -Stage Websites -DisableLogging"
    	.\DomainPrep.ps1 -Stage Websites -DisableLogging
		# Start transcript again
		#$null = Start-Transcript $ScriptLog -Append
		Write-Host ""
		
		# endregion - Run DomainPrep -Groups

		Write-Host " Installing Components."
		
		# Run Installer.ps1
		Write-Host "  Running .\Installer.ps1"

		.\Installer.ps1

	}

Exit-Script

