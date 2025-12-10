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
##region - Script Functions
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
Function Get-IsElevated {
	# Get the ID and security principal of the current user account
 	$WindowsID        = [System.Security.Principal.WindowsIdentity]::GetCurrent()
 	$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($WindowsID)
  
 	# Get the security principal for the Administrator role
 	$adminRole        = [System.Security.Principal.WindowsBuiltInRole]::Administrator
  
 	# Check to see if currently running "as Administrator"
	If ($WindowsPrincipal.IsInRole($adminRole)) { Return $True }
	Else                                        { Return $False }
}
Function Enable-PSModule {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String]$ModuleName)
	
	Write-Host -ForegroundColor 'Green' "Checking for $ModuleName PowerShell Module" 
	Try {
		If (Get-Module -ListAvailable | Where-Object {$_.Name -eq "$ModuleName"}) {
			Write-Host -ForegroundColor 'Green' "Attempting to load $ModuleName PowerShell Module..." 
			Import-Module $ModuleName -ErrorAction SilentlyContinue
			Write-Host -ForegroundColor 'Green' "$ModuleName PowerShell Module Loaded"
		}	
		Else {
			Write-Host -ForegroundColor 'Red' "Can not find the $ModuleName PowerShell Module"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	Catch [System.Exception] {
		Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
		Stop-Transcript
		Exit $ERRORLEVEL
	}	
}	
Function Get-ConfigXML {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String] $XMLFilePath)
	
	If (Test-Path "$XMLFilePath") {
        Try {
			Write-Host " Loading Variable.xml... " -NoNewline
			$global:Variable = [XML](Get-Content "$XMLFilePath" -ErrorAction Stop)
			Write-Host -ForegroundColor 'Green' "Loaded"
			
			# Script Domain Variables
			Write-Host -ForegroundColor 'Cyan' " Setting Administrator Domain Variables" 
			[String]$Script:Domain        = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Domain
			[String]$Script:AdminUser     = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Username
			[String]$Script:AdminPassword = $Variable.Installer.VMs.Default.JoinDomain.Credentials.Password
						
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
				
				If ($_.Instance -ne $Null) {
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Instance") -Value $_.Instance
					$ServerX = $_.Server
					$InstanceX = $_.Instance
        
					If ($_.SQLCluster -ne "True") {
						$SQLVersion = $Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Version}
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Version") -Value $SQLVersion
						Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLServiceAccount") -Value ($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value
						If (($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value -ne $null) { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value ($Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value }
						Else { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value (Invoke-Expression (($Workflow.Installer.SQL.SQL | Where-Object {$_.Version -eq $SQLVersion} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value)) }
						
						$SQLPort = $Variable.Installer.SQL.Instance | Where-Object {($_.Server -eq $ServerX) -and ($_.Instance -eq $InstanceX)} | ForEach-Object {$_.Port}
						If ($SQLPort -ne $null) { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value $SQLPort }
						Else { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value "1433" }
					}
				}
				
				If ($_.SQLCluster -eq "True") {
					$ClusterX = $_.Server
					$Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Node} | Where-Object {$_.Preferred -eq "1"} | ForEach-Object {
						Set-ScriptVariable -Name $Role.Replace(" ","").Replace("Server","Node") -Value $_.Server
					}
				
					$SQLVersion = $Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Version}
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Version") -Value $SQLVersion
					Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLServiceAccount") -Value ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value
					$SQLSVCAccount = ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLServiceAccount"}).Value

					If (($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value -ne $null) { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value ($Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value }
					Else { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","SQLSAPassword") -Value (Invoke-Expression (($Workflow.Installer.SQL.SQL | Where-Object {$_.Version -eq $SQLVersion} | ForEach-Object {$_.Variable} | Where-Object {$_.Name -eq "SQLSAPassword"}).Value)) }
					
					$SQLPort = $Variable.Installer.SQL.Cluster | Where-Object {$_.Cluster -eq $ClusterX} | ForEach-Object {$_.Port}
					If ($SQLPort -ne $null) { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value $SQLPort }
					Else { Set-ScriptVariable -Name $_.Name.Replace(" ","").Replace("Server","Port") -Value "1433" }
				}
			}
		
			If ($Variable.Installer.Roles.Role | Where-Object {($_.Name -eq $Role) -and ($_.Server -eq $Server)}) {
				Set-ScriptVariable -Name $Role.Replace(" ","") -Value $Server
				Set-ScriptVariable -Name ($Role.Replace(" ","") + "Short") -Value $Server.Split(".")[0]
			}
		}
		Catch [system.exception] {
			$Validate = $false
			Write-Host -ForegroundColor 'Red' "Failed to read XML File Definitions for $xmlFileName" 
			Write-Host -ForegroundColor 'Red' "Error: $($_.Exception.Message)"
			Stop-Transcript
			Exit $ERRORLEVEL
		}
	}	
	Else {
		$Validate = $false
		Write-Host -ForegroundColor 'Red' "Unable to locate $xmlFileName"
		Stop-Transcript
		Exit $ERRORLEVEL
	}
}
Function Get-Value {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [string]$Value,
		[Parameter(Mandatory=$False, Position=1)]
        [string]$Count)
	
	If ((Invoke-Expression ("`$Variable.Installer.VMs.VM | Where-Object {`$_.Count -eq `$Count} | ForEach-Object {`$_.$Value}")) -ne $null) {
        Invoke-Expression ("Return `$Variable.Installer.VMs.VM | Where-Object {`$_.Count -eq `$Count} | ForEach-Object {`$_.$Value}")
    }
	Else {
        Invoke-Expression ("Return `$Variable.Installer.VMs.Default.$Value")
    }
}
Function Set-ScriptVariable {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [string] $Name,
		[Parameter(Mandatory=$False, Position=1)]
        [string] $Value)
	
	Invoke-Expression ("`$Script:" + $Name + " = `"" + $Value + "`"")
    If (($Name.Contains("ServiceAccount")) -and !($Name.Contains("Password")) -and ($Value -ne "")) {
        Invoke-Expression ("`$Script:" + $Name + "Domain = `"" + $Value.Split("\")[0] + "`"")
        Invoke-Expression ("`$Script:" + $Name + "Username = `"" + $Value.Split("\")[1] + "`"")
    }
}
Function Get-RegValue {
    [CmdletBinding()]
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String] $Server,
		[Parameter(Mandatory=$False, Position=1)]
        [String] $Value)
	
	Try   { $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Server) }
	Catch { $reg = $null }
	
    If ($reg -ne $Null) {
        $regKey= $reg.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Auto")
        If ($regKey -ne $Null) {
        	If ($regkey.GetValue($Value) -eq 1) { Return $True }
			Else                                { Return $False }
        }
    }
}
Function Wait-VM {
	Param (
		[Parameter(Mandatory=$False, Position=0)]
        [String] $VMName,
		[Parameter(Mandatory=$False, Position=1)]
        [String] $Domain)

	Write-Host "   Verifying access to $VMName"
	Write-Host "    Registry... " -NoNewline
    While (!(Get-RegValue -Server $VMName -Value $VMName)) { Start-Sleep 1 }
    Write-Host "Ready" -ForegroundColor Green    
	
	Write-Host "    DNS...      " -NoNewline
    While (!(Resolve-DNSName -Name "$VMName.$Domain" -ErrorAction SilentlyContinue)) {
		Invoke-Command -ComputerName $VMName -ScriptBlock {ipconfig.exe /registerdns | Out-Null}
        Start-Sleep 15
	}
	Write-Host "Ready" -ForegroundColor Green
	Write-Host ""
}
Function Test-PsRemoting { 
    Param ( 
        [Parameter(Mandatory = $true)] 
        $computername ) 
     
	Write-Host "    PowerShell Remoting... " -NoNewline 
    
	Try { 
        $errorActionPreference = "Stop" 
        $result = Invoke-Command -ComputerName $computername { 1 } 
		If ($result) {
		    Write-Host "  Passed" -ForegroundColor Green
		    return $True 
        }
	} 
    Catch { 
        Write-Host "  Failed" -foregroundColor Red
		Write-Verbose $_ 
        Return $False 
    } 
     
    If ($result -ne 1) { 
        Write-Verbose "   Failed. Unexpected results returned." -ForegroundColor Red
        Return $False 
    } 
}
Function Exit-Script {
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

Get-ConfigXML ".\Test.XML"
$Variable.Installer.Components.Component[1].Variable.Item(0).value

