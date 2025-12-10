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
$QA = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates-Anycast-QA\QA - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates-Anycast-QA\QA - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += "10.100.100.100"
    $DNSServers += "10.101.101.101"
    
    $Details = @()
        Try {
            ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
            $Result = Invoke-Command -ComputerName $server -ArgumentList (, $DNSServers) -Credential $Credential -ScriptBlock {
                param ([String[]] $DNSServers)

                $Adapter = Get-NetAdapter | Where-Object Status -eq 'Up'
                If ($Adapter.InterfaceIndex.Count -gt 0 -and $Adapter.InterfaceIndex.Count -lt 2) {
                    # Clear existing DNS servers
                    $OriginalDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
                    Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4 | Set-DnsClientServerAddress -ServerAddresses @()

                    # Assign new DNS servers
                    Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DNSServers
                    $SetDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
                }
                Else {
                    Write-Host ($Env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
                }
                Return $Adapter, $OriginalDNSServers, $SetDNSServers
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                Result = 'Success'
            })
            Write-Host ($Server + ": Complete") -ForegroundColor Green
            ('Complete') | Out-File $OutFile -Encoding ascii -Append
        }
        Catch {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                Result = $_
            })
            Write-Host ($Server + ": " + $_) -ForegroundColor Red
            ('Failed. ' + $_) | Out-File $OutFile -Encoding ascii -Append
        }
        $Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, Adapter | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
}
#$Credential = Get-Credential
#region Servers
$Servers = Get-Content D:\Henri\DNS\QA-Servers.txt
#endregion

$SBArgs = @($Credential)

Start-Jobs -ScriptBlock $QA -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both

