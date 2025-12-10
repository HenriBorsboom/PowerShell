<#
.SYNOPSIS
    PowerShell Script to create failover clusters

.DESCRIPTION
    The script takes a variety of inputs and creates a Failover cluster with a File Share Witness

.PARAMETERS
    -Resume <File>
    This allows to restart the script without re-enterring all the required inputs

.EXAMPLE
    Create-Cluster.ps1
    The script will request all the inputs required to setup the cluster

.EXAMPLE
    Create-Cluster.ps1 -Resume D:\temp\Cluster_Creation\clcbvmndvapw1.xml

.NOTES
    Author: Unknown
    Date: Unkown

.UPDATES
    Author: Henri Borsboom
    Date: 2025/09/18

    Changes:
        Reworked script logic
        Added validation of inputs
        Secured sensitive inputs
        Enabled Resume mechanism
        Added stability to the script
        Added function due create file share witness
        Added function to setup services correctly
        Fixed issue with Failover clustering not installing
        Added functionality for stretch clusters
        Fixed server restart flow
        Removed redundant pauses
        Fixed issues with server hardening
        Fixed issues with prestaging of VCO
        Fixed issues with applying security access on VCO
        Added reserving VCO IP from IPAM
#>
Param(
    [Parameter(Mandatory=$false)]
    [String] $Resume = ''    
)
#--------------------------------------
#              Functions
#--------------------------------------

Function ValidateInputs {
    Write-Host "Validating Node 01: " -NoNewline
    If (Test-Connection $Node01 -Count 2 -Quiet) {
        Write-Host "Online" -ForegroundColor Green
    }
    Else {
        Write-Host "Offline" -ForegroundColor Red
        Exit
    }

    Write-Host "Validating Node 02: " -NoNewline
    If (Test-Connection $Node02 -Count 2 -Quiet) {
        Write-Host "Online" -ForegroundColor Green
    }
    Else {
        Write-Host "Offline" -ForegroundColor Red
        Exit
    }
    
    Write-Host "Validating CNO: " -NoNewline
    If ((ValidateADObject -ADObject $CNO) -eq $True) {
        Write-Host "CNO Available" -ForegroundColor Green
    }
    Else {
        Write-Host "CNO in use" -ForegroundColor Red
        Exit
    }
    
    Write-Host "Validating VCO 1: " -NoNewline
    If ((ValidateADObject -ADObject $VCO) -eq $True) {
        Write-Host "VCO 1 Available" -ForegroundColor Green
    }
    Else {
        Write-Host "VCO 1 in use" -ForegroundColor Red
        Exit
    }

    If ($null -eq $VCO2 -or $VCO2 -ne "") {
        Write-Host "Validating VCO 2: " -NoNewline
        If ((ValidateADObject -ADObject $VCO2) -eq $True) {
            Write-Host "VCO 2 Available" -ForegroundColor Green
        }
        Else {
            Write-Host "VCO 2 in use" -ForegroundColor Red
            Exit
        }
    }
}
Function ValidateADObject {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ADObject
    )
    Import-module "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ActiveDirectory\ActiveDirectory.psd1"
    Try {
        $ComputerObject = Get-ADComputer $ADObject
        If ($null -ne $ComputerObject) {
            Return $False
        }
    }
    Catch {
        If ($_.Exception.Message -eq 'The operation returned because the timeout limit was exceeded.') {
            Try {
                $ComputerObject = Get-ADComputer $CNO
                If ($null -ne $ComputerObject) {
                    Return $False
                }
            }
            Catch {
                Return $True
            }
        }
        Else {
            Return $True
        }
    }
}
Function GetDomainController {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server,
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $DCOnly
    )

    Try {
        $DomainControllers = Get-ADDomainController -Filter *

        foreach ($DC in $DomainControllers) {
            try {
                $Computer = Get-ADComputer $Server -Server $DC.HostName -Properties MemberOf

                Switch ($DCOnly) {
                    $True {
                        Return $DC.Hostname
                    }
                    $False {
                         Check if any group contains 'ClusterSvc'
                        if ($Computer.MemberOf -match "ClusterSvc") {
                            return $DC.HostName
                        }
                    }
                }

                
            } catch {
            }
        }
    }
    Catch {
        $DomainControllers = Get-ADDomainController -Filter *

        foreach ($DC in $DomainControllers) {
            try {
                $Computer = Get-ADComputer $Server -Server $DC.HostName -Properties MemberOf

                if ($Computer.MemberOf -match "ClusterSvc") {
                    return $DC.HostName
                }
            } catch {
            }
        }
    }
}
Function CheckGroupMembership {
    Param (
        [Parameter(Mandatory=$true)]    
        [String] $Node,
        [Parameter(Mandatory=$true)]
        [String] $DC
    )
    
    $attempt = 0
    $matchedGroup = $null

    do {
        $membership = (Get-ADComputer $Node -Properties memberof -Server $DC | Select-Object -ExpandProperty MemberOf)
        $matchedGroup = $membership | Where-Object { $_ -match 'ClusterSvc-Enabled' }
        $attempt++
    } until ($matchedGroup -or $attempt -ge 60)

    if ($matchedGroup) {
        return 99, ($matchedGroup -split ',')[0].Replace('CN=','')
    } else {
        Write-Host "Group not found after 10 attempts. Exiting."
        return 0, $null
    }
    
}
Function CreateCredentials {
    Param (
        [Parameter(Mandatory=$true)]
        [String] $SDLC
    )

    Switch ($SDLC.ToUpper()) {
        'DEV' { 
            $VMMAction = Get-Credential -Message 'Credential for svc_scvmm_action_dev' -UserName 'svc_scvmm_action_dev'
            $Scorch    = Get-Credential -Message 'Credential for svc_orchestrator' -UserName 'svc_orchestrator'
        }
        'INT' { 
            $VMMAction = Get-Credential -Message 'Credential for svc_scvmm_action_dev' -UserName 'svc_scvmm_action_dev'
            $Scorch    = Get-Credential -Message 'Credential for svc_orchestrator' -UserName 'svc_orchestrator'
        }
        'QA'  { 
            $VMMAction = Get-Credential -Message 'Credential for svc_scvmm_action_dev' -UserName 'svc_scvmm_action_dev'
            $Scorch    = Get-Credential -Message 'Credential for svc_orchestrator' -UserName 'svc_orchestrator'
        }
        'PRD' {
            $VMMAction = Get-Credential -Message 'Credential for svc_scvmm_action' -UserName 'svc_scvmm_action'
            $Scorch    = Get-Credential -Message 'Credential for svc_orchestrator' -UserName 'svc_orchestrator'
        }
        'ESIG' {
            $VMMAction = Get-Credential -Message 'Credential for svc_esig_scvmm' -UserName 'svc_esig_scvmm'
            $Scorch    = Get-Credential -Message 'Credential for svc_orchestrator' -UserName 'svc_orchestrator'
        }
        Default {
            throw "Unknown SDLC value: $SDLC"
            Exit
        }
    }
    Return $VMMAction, $Scorch
}
Function HardenServer {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $Servername,
        [Parameter(Mandatory=$true)]
        [String] $ClientSecret
    )
    $CurrentLocation = $Location
    If ($SDLC -eq 'DEV' -or $SDLC -eq 'INT' -or $SDLC -eq 'QA') {
        $Location = 'NP'
    }
    ElseIf ($SDLC -eq 'PRD' -or $SDLC -eq 'DR' -or $SDLC -eq 'ESIG') {
        $Location = 'PRD'
    }

    $IDP = 'https://idp-prod.int.capinet/auth/realms/PROD/protocol/openid-connect/token'
    $ClientID = "SecurityServices"
 
    $headers = @{
        "content-type" = "application/x-www-form-urlencoded"
        "Authorization" = ("Basic", [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($ClientID+":"+$ClientSecret))) -join " ")
    }

    $creds = @{
        username = $scorch.username
        password = $scorch.GetNetworkCredential().password
        grant_type = "password"
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $response = Invoke-RestMethod $IDP -Method Post -Body $creds -Headers $headers
    $token = $response.access_token

    $secure = $false
    $SQLServer = $false
    $Cluster = $true

             
    If ( $Secure -eq $true )     { [int] $Secure = 1 }
    If ( $Secure -eq $false )    { [int] $Secure = 0 }
    If ( $SQLServer -eq $true )  { [int] $SQLServer = 1 }
    If ( $SQLServer -eq $false ) { [int] $SQLServer = 0 }
    If ( $Cluster -eq $true )    { [int] $Cluster = 1 }
    If ( $Cluster -eq $false )   { [int] $Cluster = 0 }
    
    $hash = @{scpritFriendlyName = "HardenServer";
        scriptParameters = @{
        Servername=$Servername
        Location = $Location
        Secure = $Secure
        SQLServer = $SQLServer
        Cluster = $Cluster
        SDLC = $SDLC
        SMUserName = $env:Username
        LogID = '99999999'}
        scriptTimeout = 240000
    }

    $JSON = $hash | convertto-json

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $("bearer $token"))

    $result = Invoke-RestMethod -Uri "https://cbsecpsapi.int.capinet/api/ScriptExecutionAPI/run/script" -Headers $headers -Method POST -ContentType "application/json" -Body $JSON
    $Location = $CurrentLocation
    Return $result.exitcode
}
Function RetreiveIPAMClusterIP {
    Param (
        [Int] $StartIP = 1, 
        [Parameter(Mandatory=$False)]
        [Int] $EndIP = 254
    )

    $IPAddress = (Test-Connection -Count 1 -ComputerName $Node01).IPV4Address.IPAddressToString
    $FreeIP = Invoke-Command -ComputerName 'CBSTBIPAM01' -Credential $Scorch -ArgumentList $IPAddress, $CNO, $StartIP, $EndIP -ErrorAction Stop -ScriptBlock {
        Param (
            [Parameter(Mandatory=$True)]
            [String] $IPAddress,
            [Parameter(Mandatory=$True)]
            [String] $CNO, 
            [Parameter(Mandatory=$False)]
            [Int] $StartIP,
            [Parameter(Mandatory=$False)]
            [Int] $EndIP
        )

        $NetworkInfo = $IPAddress.split('.')[0] + '.' + $IPAddress.split('.')[1] + '.' + $IPAddress.split('.')[2]
        $StartNetwork = ($NetworkInfo + '.' + $StartIP.ToString())
        $EndNetwork = ($NetworkInfo + '.' + $EndIP.ToString())

        $FreeIP = Get-IpamRange -StartIPAddress $StartNetwork -EndIPAddress $EndNetwork | Find-IpamFreeAddress -NumAddress 125 -TestReachability | Where-Object {$_."PingStatus" -eq "Noreply"} | Where-Object {$_."DnsRecordStatus" -eq "NotFound"} | Select-Object -expandproperty IPAddress | Select-Object -first 1
        Add-IpamAddress -IpAddress $FreeIP -ManagedByService IPAM -Description $CNO
        Return $FreeIP
    } 
    Return $FreeIP
}
Function InstallFailoverCluster {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $Node
    )
    $Result = Invoke-Command -Computername $Node -Credential $VMMAction -Scriptblock {
        $CurrentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        Get-Process '*tiworker*' | Stop-Process -Force
        $ErrorActionPreference = $CurrentErrorActionPreference
        If ((Get-WindowsFeature -Name Failover-Clustering).InstallState -ne 'Installed') {
            Write-Host "Installing Failover Clustering" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
            Write-Host "Restarting server" -ForegroundColor Yellow
            Restart-Computer -Force
        }
        Else {
            Write-Host "Failover Clustering is installed" -ForegroundColor Green
            Return "Installed"
        }
    }
    If ($Result -ne 'Installed') {
        WaitForServerRestart -ComputerName $Node
    }
}
Function WaitForServerRestart {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $ComputerName,
        [Parameter(Mandatory=$False)]
        [Int] $TimeoutSeconds = 600,
        [Parameter(Mandatory=$False)]
        [Int] $CheckIntervalSeconds = 10
    )

    $StartTime = Get-Date
    $IsOffline = $False

    Write-Host "Waiting for $ComputerName to go offline..." -ForegroundColor Cyan
    While ((Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -and ((Get-Date) - $StartTime).TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Seconds $CheckIntervalSeconds
    }

    $IsOffline = $True
    Write-Host "$ComputerName is offline. Waiting for it to come back online..." -ForegroundColor Yellow
    While (!(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) -and ((Get-Date) - $StartTime).TotalSeconds -lt $TimeoutSeconds) {
        Start-Sleep -Seconds $CheckIntervalSeconds
    }

    If ($IsOffline -and (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
        Write-Host "$ComputerName is back online!" -ForegroundColor Green
    } 
    Else {
        Write-Warning "Timeout reached before $ComputerName came back online."
    }
}
Function CreateClusterJob {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $CNO,
        [Parameter(Mandatory=$True)]
        [String] $Node01,
        [Parameter(Mandatory=$True)]
        [String] $Node02,
        [Parameter(Mandatory=$True)]
        [String] $ClusterIP,
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.PSCredential] $vmmaction
    )

    $PasswordAction = $vmmaction.GetNetworkCredential().password
    $UserAction = $vmmaction.GetNetworkCredential().username
    $UserAction = ($UserAction -split "/")[0]

    Invoke-Command -Computername $Node01 -Argumentlist $CNO,$Node01,$Node02,$ClusterIP,$PasswordAction,$UserAction -Credential $VMMAction -scriptblock {
        Param (
            [Parameter(Mandatory=$True)]
            [String] $CNO,
            [Parameter(Mandatory=$True)]
            [String] $Node01,
            [Parameter(Mandatory=$True)]
            [String] $Node02,
            [Parameter(Mandatory=$True)]
            [String] $ClusterIP,
            [Parameter(Mandatory=$True)]
            [String] $PasswordAction,
            [Parameter(Mandatory=$True)]
            [String] $UserAction
        )
        $CurrentErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        If (Test-Path 'C:\Temp\Cluster.ps1') {
            Remove-Item 'C:\Temp\Cluster.ps1'
        }

        If (Test-Path 'C:\Temp\ClusterOut.txt') {
            Remove-Item 'C:\Temp\ClusterOut.txt'
        }

        If (Get-ScheduledTask -Taskname 'ClusterCreate') {
            Get-Scheduledtask -Taskname 'ClusterCreate' | Unregister-ScheduledTask -Confirm:$false
        }

        $Command = "New-Cluster -Name $CNO -Node $Node01,$Node02 -StaticAddress $ClusterIP -NoStorage | Out-File C:\temp\ClusterOut.txt -append"
        'Invoke-Expression -Command ' + '"' + $Command + '"' | Out-File 'C:\Temp\Cluster.ps1' -Encoding ASCII -append

        Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds -Value 0 -Force | Out-Null
        [String] $TimeScheduleForCluster = Get-Date -Format HH:mm (Get-Date).Addhours(1)
        Get-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds | Out-Null
        SCHTASKS /Create /TN ClusterCreate /SC ONCE /TR 'powershell -command c:\temp\cluster.ps1' /ST $timescheduleforcluster /RL HIGHEST /RU capitecbank\$UserAction /RP $PasswordAction
        While (!(Get-ScheduledTask 'ClusterCreate')) {
            Start-Sleep -Seconds 5
            Write-Host "Waiting for task [ClusterCreate] to be created..." -ForegroundColor Green
        }
        $ErrorActionPreference = $CurrentErrorActionPreference
    } 
}
Function PreStageVCO {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $DC, 
        [Parameter(Mandatory=$True, Position=2)]
        [String] $CNO,
        [Parameter(Mandatory=$True, Position=3)]
        [String] $VCO, `
        [Parameter(Mandatory=$True, Position=3)]
        [object] $VMMAction
    )
    Try {
        Import-module "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ActiveDirectory\ActiveDirectory.psd1"
    $Pattern = @"
^CN=(.+?)(?:(?<!\\),|$)
"@
        $DN =  Get-ADComputer $CNO -Server $DC
        $OU = $($DN.DistinguishedName) -Replace ($Pattern)
        New-ADComputer -Name $VCO -Description "Failover cluster virtual network name account" -Path $OU -Credential $VMMAction -Server $DC | Out-Null
        Write-Host "VCO created successfully" -ForegroundColor Green
    }
    Catch {
        Write-Error $_.Exception.Message -ErrorAction Stop
    }
}
Function SetVCOACL {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $DC, 
        [Parameter(Mandatory=$True, Position=2)]
        [String] $CNO,
        [Parameter(Mandatory=$True, Position=3)]
        [String] $VCO, `
        [Parameter(Mandatory=$True, Position=3)]
        [object] $VMMAction
    )  
    Import-Module "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ActiveDirectory\ActiveDirectory.psd1"


    If ( Get-PSDrive -Name AD -ErrorAction SilentlyContinue ) { Remove-PSDrive AD -ErrorAction SilentlyContinue }
    New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "" -Server $DC -Credential $vmmaction
    $VCODistinguishedName = Get-ADComputer $VCO -Server $DC -Credential $vmmaction
    $ClusterVCO = Get-ADComputer $CNO -Server $DC -Credential $vmmaction
    $VCODistinguishedName = $VCODistinguishedName.DistinguishedName
    $VCOAcl = Get-Acl "AD:\$VCODistinguishedName"
    $SID = [System.Security.Principal.SecurityIdentifier] $ClusterVCO.SID
    $identity = [System.Security.Principal.IdentityReference] $SID
    $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
    $type = [System.Security.AccessControl.AccessControlType] "Allow"
    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
    $ACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
    $VCOAcl.AddAccessRule($ACE)
    Set-Acl -Path "AD:\$VCODistinguishedName" -AclObject $VCOAcl -ErrorAction Stop | Out-Null
    Write-Host "$CNO has been granted Full control over $VCO "
}
Function Test-WMIConnectivity {
    Try {
        Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Node01 -Credential $VMMAction -ErrorAction Stop | Out-Null
        Write-Host "Your account has access to node $Node01" -ForegroundColor Green
    }
    Catch { 
        Write-Error "Your account does not have access to node $Node01" -ErrorAction stop
    }
    
    Try {
        Get-WmiObject -Class Win32_Operatingsystem -ComputerName $Node02 -Credential $VMMAction -ErrorAction Stop | Out-Null
        Write-Host "Your account has access to node $Node02" -ForegroundColor Green
    }
    Catch {
        Write-Error "Your account does not have access to node $Node02" -ErrorAction Stop
    }
    
    Try {
        Get-WmiObject -Class Win32_Operatingsystem -ComputerName 'CBSTBIPAM01' -Credential $Scorch -ErrorAction Stop | Out-Null
        Write-Host "The Scorch account access granted to CBSTBIPAM01" -ForegroundColor Green
    }
    Catch {
        Write-Error "The Scorch account could not access CBSTBIPAM01" -ErrorAction Stop
    }
    
    Try {
        Get-WmiObject -Class Win32_Operatingsystem -ComputerName $Node01 -Credential $VMMAction -ErrorAction Stop | Out-Null
        Write-Host "The VMMAction account access granted to $Node01" -ForegroundColor Green
    }
    Catch {
        Write-Error "The VMMAction account could not access $Node01" -ErrorAction Stop
    }
    
    Try {
        Get-WmiObject -Class Win32_Operatingsystem -ComputerName $Node02 -Credential $VMMAction -ErrorAction Stop | Out-Null
        Write-Host "The VMMAction account access granted to $Node02" -ForegroundColor Green
    }
    Catch {
        Write-Error "The VMMAction account could not access $Node02" -ErrorAction stop
    }
}
Function Set-HardenServer {
    Param (
        [Parameter(Mandatory=$true)]
        [String] $ClientSecret
    )
    Write-Host "Hardening server $Node01" -ForegroundColor Yellow
    $Result = HardenServer -Servername $Node01 -ClientSecret $ClientSecret
    $LocalDC = GetDomainController -Server $Node01
    Write-Host "Executed on $LocalDC" -ForegroundColor Cyan
    
    If ($Result -ne 0) {
        Write-Error "Hardening failed on node $Node01" -ErrorAction stop
        Exit 1
    }
    Write-Host "Updating policy on $Node01" -ForegroundColor Yellow
    Invoke-Command -ComputerName $Node01 -ScriptBlock {gpupdate /force} -Credential $VMMAction | Out-Null
    $Groupcheck = CheckGroupMembership -Node $Node01 -DC $LocalDC

    If ($GroupCheck[0] -ne 99) {
        Write-Error "Groups missing on $Node01 after hardening" -ErrorAction stop
        Exit 1
    }
    Else {
        Write-Host ("Server " + $Node01 + " added successfully to " + $GroupCheck[1]) -ForegroundColor Green
    }
    Remove-Variable Result
    Remove-Variable LocalDC
    Remove-Variable GroupCheck


    Write-Host "Hardening server $Node02" -ForegroundColor Yellow
    $Result = HardenServer -Servername $Node02 -ClientSecret $ClientSecret
    $LocalDC = GetDomainController -Server $Node02
    Write-Host "Executed on $LocalDC" -ForegroundColor Cyan
    If ($Result -ne 0) {
        Write-Error "Hardening failed on node $Node02" -ErrorAction stop
        Exit 1
    }
    Write-Host "Updating policy on $Node02" -ForegroundColor Yellow
    Invoke-Command -ComputerName $Node02 -ScriptBlock {gpupdate /force} -Credential $VMMAction | Out-Null
    $GroupCheck = CheckGroupMembership -node $Node02 -DC $LocalDC
    If ($GroupCheck[0] -ne 99) {
        Write-Error "Groups missing on $Node02 after hardening" -ErrorAction stop
        Exit 1
    }
    Else {
        Write-Host ("Server " + $Node02 + " added successfully to " + $GroupCheck[1]) -ForegroundColor Green
    }
    Return $LocalDC
}
Function Get-IPAM {
	Param (
		[Parameter(Mandatory=$false)]
		[Int] $StartIP,
		[Parameter(Mandatory=$false)]
		[Int] $EndIP, 
		[Parameter(Mandatory=$false)]
        [String] $Target
    )
    If ($StartIP -ne 0 -or $EndIP -ne 0) {
        $FreeIP = RetreiveIPAMClusterIP -StartIP $StartIP -EndIP $EndIP
    }
    Else {
        $FreeIP = RetreiveIPAMClusterIP
    }
    $ClusterIP = $FreeIP.IPAddressToString
    If (!($ClusterIP)) {
        Write-Error "No cluster IP could be allocated" -ErrorAction stop
        Exit 1
    }
    Write-Host ($Target + ": " + $ClusterIP) -ForegroundColor Green
    Return $FreeIP
}
Function New-Cluster {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ClusterIP
    )
    $CurrentErrorAction = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    While (((Invoke-Command -ComputerName $Node01 -ScriptBlock {Test-Path 'C:\Temp\ClusterOut.txt'} -Credential $VMMAction) -eq $false) -and ((Invoke-Command -ComputerName $Node01 -Credential $VMMAction -ScriptBlock {(Get-Content 'c:\Temp\ClusterOut.txt').length -eq 0}))) {
        CreateClusterJob -CNO $CNO -Node01 $Node01 -Node02 $Node02 -ClusterIP $ClusterIP -vmmaction $VMMAction

        Invoke-Command -Computername $Node01 -Scriptblock {Clear-ClusterNode -Force} -Credential $VMMAction
        Invoke-Command -Computername $Node02 -Scriptblock {Clear-ClusterNode -force} -Credential $VMMAction
        Write-Host "Waiting for a further 10 seconds to update cluster config..."
        Start-Sleep -Seconds 10
        Invoke-Command -Computername $Node01 -Credential $VMMAction -Scriptblock {Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds -Value 0 -Force}
        Invoke-Command -Computername $Node01 -Credential $VMMAction -Scriptblock {Start-scheduledtask 'ClusterCreate'}
        Invoke-Command -Computername $Node01 -Credential $VMMAction -Scriptblock {
            While ((Get-ScheduledTask -Taskname 'ClusterCreate' | ForEach-Object{$_.State}) -ne 'ready') {
                Write-Host "Waiting for cluster to be created (30 seconds)" -ForegroundColor Green
                Start-Sleep -Seconds 30
            }
        }
    }
    $ErrorActionPreference = $CurrentErrorAction
}
Function SetupQuorum {
    $path = "\\prod.vast.capitecbank.fin.sky\Quorum\$SDLC\$CNO"
    New-Item -Path $path -ItemType Directory -Force | Out-Null
    $Loop = $True
    While ($Loop) {
        Try {
            Get-ADComputer $CNO -Server $env:LOGONSERVER.Replace('\\','') | Out-Null
            Get-ADComputer $Node01 -Server $env:LOGONSERVER.Replace('\\','') | Out-Null
            Get-ADComputer $Node02 -Server $env:LOGONSERVER.Replace('\\','') | Out-Null
            $Loop = $False
        }
        Catch {
            Write-Host "Setup Quorum is waiting for AD Objects replicate to the local domain controller (10s)" -ForegroundColor Cyan
            Start-Sleep -Seconds 10
        }
    }
    $CNOIdentity = "capitecbank\$CNO$"
    icacls $path /grant "${CNOIdentity}:(OI)(CI)F"

    $NodeNames = @($Node01, $Node02)
    foreach ($node in $NodeNames) {
        $nodeIdentity = "capitecbank\$node$"
        icacls $path /grant "${nodeIdentity}:(OI)(CI)F"
    }
    Invoke-Command $Node01 -Credential $VMMAction -ArgumentList $Path -ScriptBlock {
        Param (
            [Parameter(Mandatory=$True)]
            [String] $Path
        )
        Set-ClusterQuorum -FileShareWitness $Path | Out-Null
    }
    Write-Host ("Cluster set to use File Share Witness as quorum on " + $Path) -ForegroundColor Green
}
Function SetServices {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Node01,
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Node02
    )
    Set-Service -ComputerName $Node01 -Name ClusSvc -StartupType Automatic
    Set-Service -ComputerName $Node02 -Name ClusSvc -StartupType Automatic
    Invoke-Command -ComputerName $Node01 -Credential $VMMAction -ScriptBlock { Start-Service Clussvc }
    Invoke-Command -ComputerName $Node02 -Credential $VMMAction -ScriptBlock { Start-Service Clussvc }

}
$ValidateInput = $True
If ([string]::IsNullOrWhiteSpace($Resume) -or $Resume -eq "") {
    $Node01        = Read-host -Prompt "Please provide the first node name [Not FQDN]"
    $Node02        = Read-Host -Prompt "Please provide the second node name [Not FQDN]"
    $CNO           = Read-Host -Prompt "Please provide the cluster name object [CNO]"
    $VCO           = Read-Host -Prompt "Please provide the virtual computer name object 1 [VCO]"
    $VCO2          = Read-Host -Prompt "Please provide the virtual computer name object 2 [VCO] (Leave empty if not required)"
    $StartIP       = Read-Host -Prompt "Please provide the Start IP of the subnet (Only the last Octet. Leave blank if /24 CIDR range)"
    $EndIP         = Read-Host -Prompt "Please provide the End IP of the subnet (Only the last Octet. Leave blank if /24 CIDR range)"
    Do {
        $SDLC = Read-Host -Prompt "Please provide SDLC [DEV/INT/QA/PRD/ESIG]"
        $isValid = $SDLC -in @("DEV", "INT", "QA", "PRD", "ESIG")

        if (-not $isValid) {
            Write-Host "Invalid input. Please enter either 'DEV', 'INT', 'QA', 'PRD', 'ESIG'." -ForegroundColor Red
        }
    } while (-not $isValid)
    Do {
        $Location = Read-Host -Prompt "Please provide Location [BLIS/BFTC]"
        $isValid = $Location -in @("BLIS", "BFTC")

        if (-not $isValid) {
            Write-Host "Invalid input. Please enter either 'BLIS' or 'BFTC'." -ForegroundColor Red
        }
    } while (-not $isValid)
    Do {
        $MultiIP = Read-Host -Prompt "Are multiple IP addresses required (Stretch Cluster) [Y/n]"
        $MultiIP = $MultiIP.ToLower()

        If ($MultiIP -notin @("y", "n")) {
            Write-Host "Invalid input. Please enter 'Y' for yes or 'N' for no." -ForegroundColor Red
        }
    } While ($MultiIP -notin @("y", "n"))
    $ClientSecret  = Read-Host -Prompt "Please enter the production clientID (SecurityServices) password to retrieve token from IDP" -AsSecureString
    $VMMAction,$Scorch = CreateCredentials -SDLC $SDLC
    
    
    If ($ValidateInput -eq $True) {
        Try {
            ValidateInputs -ErrorAction stop
        }
        Catch{
            $Error[0].Exception
            write-error "Please review the error and modify parameters" -ErrorAction stop
        }
        Finally {
            $ValidateInput = $False
        }
    }
    If ($MultiIP -eq 'y') {
        Write-Host "Please reserve the addresses in IPAM manually" -ForegroundColor Red -BackgroundColor Yellow
        $IP1 = Read-Host -Prompt "Please provide the IP address for Node 1"
        $IP2 = Read-Host -Prompt "Please provide the IP address for Node 2"
        $FreeIP = $IP1, $IP2 -join ','
    }
    Else {
        Write-Host "Getting IPAM IP for CNO" -ForegroundColor Yellow
        $FreeIP = Get-IPAM -StartIP $StartIP -EndIP $EndIP -Target "CNO"
        Write-Host "Getting IPAM IP for VCO" -ForegroundColor Yellow
        $VCOIP = Get-IPAM -StartIP $StartIP -EndIP $EndIP -Target "VCO"
    }
    $UserInput = New-Object -TypeName PSObject -Property @{
        Node01       = $Node01
        Node02       = $Node02
        CNO          = $CNO
        VCO          = $VCO
        VCO2         = $VCO2
        StartIP      = $StartIP
        EndIP        = $EndIP
        SDLC         = $SDLC
        Location     = $Location
        MultiIP      = $MultiIP
        ClientSecret = $ClientSecret
        VMMAction    = $VMMAction
        Scorch       = $Scorch
        FreeIP       = $FreeIP
        VCOIP        = $VCOIP
    }
    $UserInput | Export-Clixml -Path ("D:\temp\Cluster_Creation\" + $CNO + ".xml")
    Write-Host ('In case of failure, run Create-Cluster.ps1 -Resume ' + ("D:\temp\Cluster_Creation\" + $CNO + ".xml")) -BackgroundColor Red -ForegroundColor Black
}
Else {
    $UserInput = Import-Clixml -Path $Resume
    $Node01 = $UserInput.Node01
    $Node02 = $UserInput.Node02
    $CNO = $UserInput.CNO
    $VCO = $UserInput.VCO
    $VCO2 = $UserInput.VCO2
    $StartIP = $UserInput.StartIP
    $EndIP = $UserInput.EndIP
    $SDLC = $UserInput.SDLC
    $Location = $UserInput.Location
    $MultiIP = $UserInput.MultipleIP
    $ClientSecret = $UserInput.ClientSecret
    $VMMAction = $UserInput.VMMAction
    $Scorch = $UserInput.Scorch
    $FreeIP = $UserInput.FreeIP
}
If ($ValidateInput -eq $True) {
    Try {
        ValidateInputs -ErrorAction stop
    }
    Catch{
        $Error[0].Exception
        write-error "Please review the error and modify parameters" -ErrorAction stop
    }
    Finally {
        $ValidateInput = $False
    }
}

Write-Host "Testing WMI Connectivity" -ForegroundColor Cyan
Test-WMIConnectivity
Write-Host "Checking if Failover Clustering is installed on $Node01" -ForegroundColor Cyan
InstallFailoverCluster -Node $Node01
Write-Host "Checking if Failover Clustering is installed on $Node02" -ForegroundColor Cyan
InstallFailoverCluster -Node $Node02
Write-Host "Hardening Servers" -ForegroundColor Cyan

$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ClientSecret)
$ClientSecret_String = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

$LocalDC = Set-HardenServer -ClientSecret $ClientSecret_String
Write-Host "Creating Cluster" -ForegroundColor Cyan
New-Cluster -ClusterIP $FreeIP

$LocalDC = GetDomainController -Server $CNO -DCOnly
If ($VCO2 -ne '') {
    Write-Host "Prestaging the $VCO" -ForegroundColor Cyan
    PreStageVCO -VCO $VCO -CNO $CNO -DC $LocalDC -vmmaction $vmmaction
    Write-Host "Applying security on $VCO" -ForegroundColor Cyan
    SetVCOACL -CNO $CNO -VCO $VCO -DC $LocalDC -vmmaction $vmmaction
    
    Write-Host "Prestaging the $VCO2" -ForegroundColor Cyan
    PreStageVCO -VCO $VCO2 -CNO $CNO -DC $LocalDC -vmmaction $vmmaction
    Write-Host "Applying security on $VCO" -ForegroundColor Cyan
    SetVCOACL -CNO $CNO -VCO $VCO2 -DC $LocalDC -vmmaction $vmmaction
}
Else {
    
    Write-Host "Prestaging the $VCO" -ForegroundColor Cyan
    PreStageVCO -VCO $VCO -CNO $CNO -DC $LocalDC -vmmaction $vmmaction
    Write-Host "Applying security on $VCO" -ForegroundColor Cyan
    SetVCOACL -CNO $CNO -VCO $VCO -DC $LocalDC -vmmaction $vmmaction
}

Write-Host "Setting up quorum" -ForegroundColor Cyan
SetupQuorum
SetServices

Write-Host "-------------------------------" -ForegroundColor Green
Write-Host "Cluster created successfully"
Write-Host "-------------------------------" -ForegroundColor Green
Write-Host "Node 01: $Node01" -ForegroundColor Cyan
Write-Host "Node 02: $Node02" -ForegroundColor Cyan
Write-Host "CNO    : $CNO" -ForegroundColor Cyan
Write-Host "CNO IP : $FreeIP" -ForegroundColor Cyan
Write-Host "VCO    : $VCO" -ForegroundColor Cyan
Write-Host "VCO IP : $VCOIP" -ForegroundColor Cyan
Write-Host "-------------------------------" -ForegroundColor Green
Remove-Item ("D:\temp\Cluster_Creation\" + $CNO + ".xml") -Force