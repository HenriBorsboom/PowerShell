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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { 
            Write-Host ("Starting Jobs for " + $Targets.Count.ToString() + " targets. Please wait for the results.")
        }
    }
    For ($Index = 0; $Index -lt $Targets.Count; $Index ++) {
        $Target = $Targets[$index]
        Switch ($ReportImmediate) {
            $False { 
                Write-Host (($Index + 1).ToString() + '/' + $Targets.Count.ToString() + ' - Starting Job for ' + $Target)
            }
        }
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
            #$FinishedJobs = Wait-Job -Job $Jobs -Any
            #$FinishedJobs | Receive-Job
            #$FinishedJobs | Remove-Job -Force
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
#Example of Use
Clear-Host
$BFTCNPRD = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.225.97.201")
    $DNSServers += ,("10.225.97.202")
    $DNSServers += ,("10.224.106.200")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    #For ($i = 0; $i -lt $Servers.Count; $i ++) {
        #Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
        Try {
            ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
            $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -Credential $Credential -ScriptBlock {
                param ($dnsServers, $dnsSuffixSearchOrder)

                $Adapter = Get-NetAdapter | Where-Object Status -eq 'Up'
                If ($Adapter.InterfaceIndex.Count -gt 0 -and $Adapter.InterfaceIndex.Count -lt 2) {
                    # Clear existing DNS servers
                    $OriginalDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
                    Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4 | Set-DnsClientServerAddress -ServerAddresses @()

                    # Assign new DNS servers
                    Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DNSServers
                    $SetDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses

                    # Clear existing DNS suffix search order
                    $OriginalSuffixSearchList = (Get-DnsClientGlobalSetting).SuffixSearchList
                    Set-DnsClientGlobalSetting -SuffixSearchList @()

                    # Set new DNS suffix search order
                    Set-DnsClientGlobalSetting -SuffixSearchList $dnsSuffixSearchOrder
                    $SetSuffixSearchOrder = (Get-DnsClientGlobalSetting).SuffixSearchList
                }
                Else {
                    Write-Host ($Server + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
                }
                Return $Adapter, $OriginalDNSServers, $SetDNSServers, $OriginalSuffixSearchList, $SetSuffixSearchOrder
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
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
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
                Result = $_
            })
            Write-Host ($Server + ": " + $_) -ForegroundColor Red
            ('Failed. ' + $_) | Out-File $OutFile -Encoding ascii -Append
        }
        $Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, OriginalSuffixSearchList, SetSuffixSearchOrder, Adapter | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
    #}
    
}
$BLISNPRD = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.106.200")
    $DNSServers += ,("10.224.106.201")
    $DNSServers += ,("10.225.97.201")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    #For ($i = 0; $i -lt $Servers.Count; $i ++) {
        #Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
        Try {
            ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
            $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -Credential $Credential -ScriptBlock {
                param ($dnsServers, $dnsSuffixSearchOrder)

                $Adapter = Get-NetAdapter | Where-Object Status -eq 'Up'
                If ($Adapter.InterfaceIndex.Count -gt 0 -and $Adapter.InterfaceIndex.Count -lt 2) {
                    # Clear existing DNS servers
                    $OriginalDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses
                    Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4 | Set-DnsClientServerAddress -ServerAddresses @()

                    # Assign new DNS servers
                    Set-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -ServerAddresses $DNSServers
                    $SetDNSServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.InterfaceIndex -AddressFamily IPv4).ServerAddresses

                    # Clear existing DNS suffix search order
                    $OriginalSuffixSearchList = (Get-DnsClientGlobalSetting).SuffixSearchList
                    Set-DnsClientGlobalSetting -SuffixSearchList @()

                    # Set new DNS suffix search order
                    Set-DnsClientGlobalSetting -SuffixSearchList $dnsSuffixSearchOrder
                    $SetSuffixSearchOrder = (Get-DnsClientGlobalSetting).SuffixSearchList
                }
                Else {
                    Write-Host ($Server + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
                }
                Return $Adapter, $OriginalDNSServers, $SetDNSServers, $OriginalSuffixSearchList, $SetSuffixSearchOrder
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
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
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
                Result = $_
            })
            Write-Host ($Server + ": " + $_) -ForegroundColor Red
            ('Failed. ' + $_) | Out-File $OutFile -Encoding ascii -Append
        }
        $Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, OriginalSuffixSearchList, SetSuffixSearchOrder, Adapter | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
    #}
    
}
#$Credential = Get-Credential
$Servers = @()
$Servers += ('CCDEVAPP013')
$Servers += ('cbvmnqadbw016')
$Servers += ('cbvmnqadbw018')
$Servers += ('cbvmnqadbw020')
$Servers += ('cbvmnqadbw021')
$Servers += ('cbvmnqadbw022')
$Servers += ('cbvmnqadbw023')
$Servers += ('cbvmndvapw017')
$Servers += ('cbvmndvapw018')
$Servers += ('cbvmndvapw020')
$Servers += ('cbvmndvapw029')
$Servers += ('cbvmndvapw030')
$Servers += ('cbvmndvapw031')
$Servers += ('cbvmndvapw051')
$Servers += ('cbvmndvapw052')
$Servers += ('cbvmndvapw073')
$Servers += ('cbvmndvapw096')
$Servers += ('cbvmndvapw097')
$Servers += ('cbvmndvapw099')
$Servers += ('cbvmndvapw100')
$Servers += ('cbvmndvapw101')
$Servers += ('cbvmndvapw112')
$Servers += ('cbvmndvapw116')
$Servers += ('cbvmndvapw117')
$Servers += ('cbvmndvapw119')
$Servers += ('cbvmndvdbw034')
$Servers += ('cbvmndvdbw035')
$Servers += ('cbvmndvdbw037')
$Servers += ('cbvmndvdbw046')
$Servers += ('cbvmndvdbw047')
$Servers += ('cbvmndvdbw049')
$Servers += ('cbvmndvdbw054')
$Servers += ('cbvmndvdbw055')
$Servers += ('cbvmndvdbw056')
$Servers += ('cbvmndvdbw057')
$Servers += ('cbvmndvwfw002')
$Servers += ('cbvmndvwfw011')
$Servers += ('cbvmnitapw007')
$Servers += ('cbvmnitapw008')
$Servers += ('cbvmnitapw010')
$Servers += ('cbvmnitapw014')
$Servers += ('cbvmnitapw017')
$Servers += ('cbvmnitapw021')
$Servers += ('cbvmnitapw022')
$Servers += ('cbvmnitapw023')
$Servers += ('cbvmnitapw029')
$Servers += ('cbvmnitdbw003')
$Servers += ('cbvmnitdbw006')
$Servers += ('cbvmnitdbw015')
$Servers += ('cbvmnitdbw017')
$Servers += ('cbvmndvapw120')
$Servers += ('cbvmnitdbw005')
$Servers += ('cbvmnqaapw038')
$Servers += ('cbvmndvdbw031')
$Servers += ('cbvmndvdbw033')
$Servers += ('cbvmndvapw050')
$Servers += ('cbvmndvapw072')
$Servers += ('cbvmndvapw074')
$Servers += ('CBWLNDVAP2025')
$Servers += ('ccdevdb002')
$Servers += ('CBMFTDEV01')
$Servers += ('CBMFTGWDEV01')
$Servers += ('ccdevdb004')
$Servers += ('ccdevdb033')
$Servers += ('CBMGTDEV01')
$Servers += ('CBMOSDEV01')
$Servers += ('CBPODEV')
$Servers += ('CBPOINT')
$Servers += ('CBPOQA')
$Servers += ('CBPOSTINT04')
$Servers += ('CBRBAINT04')
$Servers += ('CBSTBCLOGSDEV01')
$Servers += ('CBSTBDMCSINT01')
$Servers += ('CBSTBDMTCDEV')
$Servers += ('CBSTBDMTCINT')
$Servers += ('ccdevdb264')
$Servers += ('ccdevwf016')
$Servers += ('CBUTLDEV01')
$Servers += ('CBWFINT09')
$Servers += ('ccintapp002')
$Servers += ('ccintapp009')
$Servers += ('ccintapp017')
$Servers += ('CBWLNDVAPW114')
$Servers += ('CBWLNDVAPW115')
$Servers += ('ccqaapp032')
$Servers += ('ccqaapp069')
$Servers += ('ccqadb029')
$Servers += ('ccqadb080')
$Servers += ('ccqawf052')
$Servers += ('CBWLNITAPW001')
$Servers += ('CBWLNITAPW043')
$Servers += ('CBWLNQAAPW034')
$Servers += ('CBWLNQAWFW018')
$Servers += ('CBWLNQAWFW020')
$Servers += ('CBWSBLDEV01')
$Servers += ('CCDEVAPP086')
$Servers += ('CCINTDB002')
$Servers += ('CCQAWF001')
$Servers += ('CCQAWF002')
$Servers += ('CB0061')


$SBArgs = @($Credential)
#Start-Jobs -ScriptBlock $BFTCNPRD -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
Start-Jobs -ScriptBlock $BLISNPRD -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10