Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; sleep 1 }
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both","None")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False, `
        [Parameter(Mandatory=$False, Position=6)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS
    )

    $Jobs = @()
    
    For ($Index = 0; $Index -lt $Targets.Count; $Index ++) {
        $Target = $Targets[$index]
        Write-Host (($Index + 1).ToString() + '/' + $Targets.Count.ToString() + ' - Starting Job for ' + $Target)
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)
            }
            "None" { $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock ) }
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $ActiveJob = Get-Job | Where State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where State -eq 'Running' | Receive-Job
                }
                $False {
                    If ($Null -ne $ActiveJob) {
                        Receive-Job $ActiveJob | Remove-Job $ActiveJob
                    }
                }
            }
            $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}

#Example of Use
Clear-Host
$DNSHostsAudit1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    
    $ErroractionPreference = 'Stop'

    $OutFile = ('C:\Temp\Henri\DNSHostsAudit3\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSHostsAudit3\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    $Details = @()
    Try {
        ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
        [Object[]] $Result = Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
            Function Get-ConfiguredHosts {
                # Define the path to the hosts file
                $Hosts = @()
                # Read and filter the hosts file
                Get-Content -Path "C:\windows\system32\drivers\etc\hosts" | ForEach-Object {
                    # Skip lines starting with '#' (comments) or empty lines
                    if ($_ -notmatch "^\s*#|^\s*$") {
                        # Use regex to match and split IP and hostname
                        if ($_ -match "^\s*(\d{1,3}(\.\d{1,3}){3}|::1)\s+(\S+)") {
                            # Output the matched IP and hostname
                            $Hosts += ,($matches[1] + " " + $matches[3])
                        }
                    }
                }
                Return $Hosts -join ';'
            }
            [Object[]] $AdapterGUIDs = Get-NetAdapter | Select-Object InterfaceGuid
            $ReturnDetails = @()
            ForEach ($AdapterGUID in $AdapterGUIDs) {
                $DHCPIPAddress = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).DHCPIPAddress
                $IPAddress = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).IPAddress
                $DHCPNameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).DhcpNameServer
                $NameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).NameServer
                If ($null -ne $DHCPNameServer) {
                    $DHCPServerPublished = $True
                }
                Else {
                    $DHCPServerPublished = $False
                }
                If ($NameServer -eq '' -and -not $DHCPNameServer -eq $null) {
                    $DHCPInUse = $True
                }
                Else {
                    $DHCPInUse = $false
                }
                If ($null -ne $IPAddress) {
                    $IP = $IPAddress[0]
                }
                Else {
                    $IP = $null
                }
                $Hosts = Get-ConfiguredHosts
                $ReturnDetails += ,(New-Object -TypeName PSObject -Property @{
                    Server = $env:COMPUTERNAME
                    DHCPNameServer = $DHCPNameServer
                    NameServer = $NameServer
                    DHCPServerPublished = $DHCPServerPublished
                    DHCPInUse = $DHCPInUse
                    Hosts = $Hosts
                    IPAddress = $IP
                    DHCPIPAddress = $DHCPIPAddress
                })
            }
            
            Return $ReturnDetails
        }
        ForEach ($Object in $Result) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Object.Server
                DHCPNameServer = $Object.DHCPNameServer
                NameServer = $Object.NameServer
                DHCPServerPublished = $Object.DHCPServerPublished
                DHCPInUse = $Object.DHCPInUse
                Hosts = $Object.Hosts
                IPAddress = $Object.IPAddress
                DHCPIPAddress = $Object.DHCPIPAddress
                Result = 'Success'
            })
        }
        Write-Host ($Server + ": Complete") -ForegroundColor Green
        $Result | Format-Table | Out-File $OutFile -Encoding ascii -Append
        ('Complete') | Out-File $OutFile -Encoding ascii -Append
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server 
            DHCPNameServer = $null
            NameServer = $null
            DHCPServerPublished = $null
            DHCPInUse = $null
            Hosts = $null
            IPAddress = $null
            DHCPIPAddress = $null
            Result = $_.Exception.Message
        })
        Write-Host ($Server + ": " + $_.Exception.Message) -ForegroundColor Red
        ('Failed. ' + $_.Exception.Message) | Out-File $OutFile -Encoding ascii -Append
    }
    $Params = @("Server", "DHCPNameServer", "NameServer", "DHCPServerPublished", "DHCPInUse", "Hosts", "IPAddress", "DHCPIPAddress", "Result")
    $Details | Select-Object $Params | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
}
Function Get-DomainServers {
    $LogonDate = (Get-Date).AddMonths(-2)
    $Servers = Get-ADComputer -Filter {Enabled -eq $True -and LastLogonDate -gt $LogonDate -and OperatingSystem -like '*server*'} -Properties LastLogonDate, Enabled, OperatingSystem
    Return $Servers.Name
}
#$Credential = Get-Credential

$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $DNSHostsAudit1 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
