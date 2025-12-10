Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; Start-Sleep 1 }
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
            $ActiveJob = Get-Job | Where-Object State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where-Object State -eq 'Running' | Receive-Job
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
$DNSDHCPHostSettings = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSDHCPHostSettings\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSDHCPHostSettings\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    $Details = @()
    Try {
        ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
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
            ForEach ($AdapterGUID in $AdapterGUIDs) {
                $DHCPNameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).DhcpNameServer
                $NameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).NameServer
                If ($DHCPNameServer -ne '') {
                    $DHCPServerPublished = $True
                }
                Else {
                    $DHCPServerPublished = $True
                }
                If ($NameServer -eq '') {
                    $DHCPInUse = $True
                }
                Else {
                    $DHCPInUse = $false
                }
            }
            $Hosts = Get-ConfiguredHosts
            Return $DHCPNameServer, $NameServer, $DHCPServerPublished, $DHCPInUse, $Hosts
        }
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            DHCPNameServer = $Result[0]
            NameServer = $Result[1]
            DHCPServerPublished = $Result[2]
            DHCPInUse = $Result[3]
            Hosts = $Result[4]
            Result = 'Success'
        })
        Write-Host ($Server + ": Complete") -ForegroundColor Green
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
            Result = $_.Exception.Message
        })
        Write-Host ($Server + ": " + $_.Exception.Message) -ForegroundColor Red
        ('Failed. ' + $_.Exception.Message) | Out-File $OutFile -Encoding ascii -Append
    }
    $Params = @("Server", "DHCPNameServer", "NameServer", "DHCPServerPublished", "DHCPInUse", "Hosts", "Result")
    $Details | Select-Object $Params | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
}
Function Get-DomainServers {
    $LogonDate = (Get-Date).AddMonths(-2)
    $Servers = Get-ADComputer -Filter {Enabled -eq $True -and LastLogonDate -gt $LogonDate -and OperatingSystem -like '*server*'} -Properties LastLogonDate, Enabled, OperatingSystem
    Return $Servers.Name
}
#$Servers = Get-DomainServers
#$Credential = Get-Credential


$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $DNSDHCPHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10

