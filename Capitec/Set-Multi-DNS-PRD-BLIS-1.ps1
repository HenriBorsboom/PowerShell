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
$BLISPRD1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates1\BLIS Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates1\BLIS Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.97.200")
    $DNSServers += ,("10.224.97.220")
    $DNSServers += ,("10.225.97.202")

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
$Servers += ,('cbvmpprapw024')
$Servers += ,('cbvmpprapw030')
$Servers += ,('cbvmpprapw042')
$Servers += ,('cbvmpprapw047')
$Servers += ,('cbvmpprapw061')
$Servers += ,('cbvmpprapw080')
$Servers += ,('cbvmpprapw083')
$Servers += ,('cbvmpprapw084')
$Servers += ,('cbvmpprapw086')
$Servers += ,('cbvmpprapw087')
$Servers += ,('cbvmpprapw088')
$Servers += ,('cbvmpprapw091')
$Servers += ,('cbvmpprapw092')
$Servers += ,('cbvmpprapw094')
$Servers += ,('cbvmpprapw097')
$Servers += ,('cbvmpprapw098')
$Servers += ,('cbvmpprapw137')
$Servers += ,('cbvmpprapw140')
$Servers += ,('cbvmpprapw141')
$Servers += ,('cbvmpprapw142')
$Servers += ,('cbvmpprapw143')
$Servers += ,('cbvmpprapw144')
$Servers += ,('cbvmpprdbw010')
$Servers += ,('cbvmpprdbw014')
$Servers += ,('cbvmpprdbw016')
$Servers += ,('cbvmpprwfw010')
$Servers += ,('cbvmpprwfw011')
$Servers += ,('cbvmpprwfw013')
$Servers += ,('cbvmpprwfw014')
$Servers += ,('cbvmpprapw012')
$Servers += ,('cbvmpprapw021')
$Servers += ,('cbvmpprapw104')
$Servers += ,('cbvmpprdbw011')
$Servers += ,('CB0242')
$Servers += ,('CBSTBADRMS01')
$Servers += ,('CB0153')
$Servers += ,('CB0251')
$Servers += ,('CB0256')
$Servers += ,('CB0274')
$Servers += ,('CB0275')
$Servers += ,('CB0276')
$Servers += ,('CBAGPM01')
$Servers += ,('CBARR01')
$Servers += ,('CBBSCS02')
$Servers += ,('CBBSCS03')
$Servers += ,('CBCAPRAPP01')
$Servers += ,('CBCAPRDB01')
$Servers += ,('CBDLS01')
$Servers += ,('CBDLS02')
$Servers += ,('CBLOGCOL02')
$Servers += ,('CBNXB01')
$Servers += ,('CBSTBCA01')
$Servers += ,('CBSTBCE01')
$Servers += ,('CBSTBEUCMAN01')
$Servers += ,('CBSTBLC01')
$Servers += ,('CBSTBNPS05')
$Servers += ,('CBSTBPD')
$Servers += ,('CBSTBSASCS01')
$Servers += ,('CBSTBSASMS01')
$Servers += ,('CBSTBSASMT01')
$Servers += ,('CBSTBSCCM01')
$Servers += ,('CBSTBSCCM02')
$Servers += ,('CBSTBSCCM04')
$Servers += ,('CBWEBSENSEDLP01')
$Servers += ,('CBWFLS01')
$Servers += ,('CBWLPPRAPW004')
$Servers += ,('CBWLPPRAPW005')
$Servers += ,('CBWLPPRAPW006')
$Servers += ,('CBWLPPRAPW007')
$Servers += ,('CBWLPPRAPW110')
$Servers += ,('CBWLPPRAPW182')
$Servers += ,('CBWLPPRAPW183')
$Servers += ,('CBWLPPRWFW001')
$Servers += ,('CBWLPPRWFW002')
$Servers += ,('CCPRDAPP255')
$Servers += ,('CCPRDDB136')
$Servers += ,('cbstbipam01')
$Servers += ,('cbstbvipdb01')
$Servers += ,('ccprdapp037')
$Servers += ,('ccprdapp057')
$Servers += ,('ccprdapp062')
$Servers += ,('ccprdapp137')
$Servers += ,('ccprdapp138')
$Servers += ,('ccprdapp252')
$Servers += ,('ccprdapp253')
$Servers += ,('ccprdapp294')
$Servers += ,('ccprdapp295')
$Servers += ,('ccprdapp404')
$Servers += ,('ccprddb009')
$Servers += ,('ccprddb025')
$Servers += ,('ccprdwf002')
$Servers += ,('ccprdwf003')
$Servers += ,('CBDBPPRDBW010')
$Servers += ,('CBDBPPRDBW018')
$Servers += ,('CBDBPPRDBW019')
$Servers += ,('CBDBPPRDBW020')
$Servers += ,('CBDBPPRDBW021')
$Servers += ,('CBDBPPRDBW048')
$Servers += ,('CBDC002')
$Servers += ,('CBDC004')
$Servers += ,('CBDC005')
$Servers += ,('CBDC006')
$Servers += ,('CBMGPPRAPW010')
$Servers += ,('CBNBMGT1001')
$Servers += ,('CBNBOPSCENTER')
$Servers += ,('CBPORT')
$Servers += ,('CBPOST01')
$Servers += ,('CBSD01')
$Servers += ,('CBSTBPRN01')
$Servers += ,('CBWLPPRAPW011')
$Servers += ,('CBWLPPRAPW022')
$Servers += ,('CBWLPPRAPW024')
$Servers += ,('CBWLPPRAPW025')
$Servers += ,('CBWLPPRAPW027')
$Servers += ,('CBWLPPRAPW033')
$Servers += ,('CBWLPPRAPW034')
$Servers += ,('CBWLPPRAPW035')

$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BLISPRD1 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10