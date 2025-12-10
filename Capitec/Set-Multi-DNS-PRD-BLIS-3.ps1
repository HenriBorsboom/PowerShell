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
$BLISPRD3 = {
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
    $DNSServers += ,("10.224.97.221")
    $DNSServers += ,("10.224.97.200")
    $DNSServers += ,("10.225.97.221")

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
$Servers += ,('cbwlpprapw383')
$Servers += ,('cbwlpprapw387')
$Servers += ,('cbwlpprapw389')
$Servers += ,('cbwlpprapw393')
$Servers += ,('cbwlpprapw399')
$Servers += ,('cbwlpprapw407')
$Servers += ,('cbwlpprapw412')
$Servers += ,('cbwlpprapw424')
$Servers += ,('cbwlpprapw427')
$Servers += ,('cbwlpprapw431')
$Servers += ,('cbwlpprapw432')
$Servers += ,('cbwlpprapw443')
$Servers += ,('cbwlpprapw453')
$Servers += ,('cbwlpprapw466')
$Servers += ,('cbwlpprapw479')
$Servers += ,('cbwlpprapw481')
$Servers += ,('cbwlpprapw484')
$Servers += ,('cbwlpprapw485')
$Servers += ,('cbwlpprapw486')
$Servers += ,('cbwlpprapw491')
$Servers += ,('cbwlpprapw492')
$Servers += ,('cbwlpprapw501')
$Servers += ,('cbwlpprapw502')
$Servers += ,('cbwlpprapw506')
$Servers += ,('cbwlpprapw524')
$Servers += ,('cbwlpprapw543')
$Servers += ,('cbwlpprapw564')
$Servers += ,('cbwlpprapw567')
$Servers += ,('cbwlpprapw575')
$Servers += ,('cbwlpprapw578')
$Servers += ,('cbwlpprapw598')
$Servers += ,('cbwlpprapw603')
$Servers += ,('cbwlpprapw604')
$Servers += ,('cbwlpprapw607')
$Servers += ,('cbwlpprapw614')
$Servers += ,('cbwlpprapw628')
$Servers += ,('cbwlpprapw647')
$Servers += ,('cbwlpprapw648')
$Servers += ,('cbwlpprapw649')
$Servers += ,('cbwlpprapw650')
$Servers += ,('cbwlpprapw651')
$Servers += ,('cbwlpprapw652')
$Servers += ,('cbwlpprdbw185')
$Servers += ,('cbwlpprdbw187')
$Servers += ,('cbwlpprdbw214')
$Servers += ,('cbwlpprdbw215')
$Servers += ,('cbwlpprdbw224')
$Servers += ,('cbwlpprdbw225')
$Servers += ,('cbwlpprdbw253')
$Servers += ,('cbwlpprdbw255')
$Servers += ,('cbwlpprdbw257')
$Servers += ,('cbwlpprdbw258')
$Servers += ,('cbwlpprdbw269')
$Servers += ,('cbwlpprdbw270')
$Servers += ,('cbwlpprdbw272')
$Servers += ,('cbwlpprdbw285')
$Servers += ,('cbwlpprdbw292')
$Servers += ,('cbwlpprdbw293')
$Servers += ,('cbwlpprdbw294')
$Servers += ,('cbwlpprdbw297')
$Servers += ,('cbwlpprdbw300')
$Servers += ,('cbwlpprdbw301')
$Servers += ,('cbwlpprdbw304')
$Servers += ,('cbwlpprdbw309')
$Servers += ,('cbwlpprdbw319')
$Servers += ,('cbwlpprdbw320')
$Servers += ,('cbwlpprdbw334')
$Servers += ,('cbwlpprdbw336')
$Servers += ,('cbwlpprdbw339')
$Servers += ,('cbwlpprwfw063')
$Servers += ,('cbwlpprwfw064')
$Servers += ,('cbwlpprwfw065')
$Servers += ,('cbwlpprwfw066')
$Servers += ,('cbwlpprwfw067')
$Servers += ,('cbwlpprwfw087')
$Servers += ,('cbwlpprwfw088')
$Servers += ,('cbwlpprwfw109')
$Servers += ,('cbwlpprwfw110')
$Servers += ,('ccdrapp106')
$Servers += ,('ccprdapp034')
$Servers += ,('ccprdapp048')
$Servers += ,('ccprdapp051')
$Servers += ,('ccprdapp063')
$Servers += ,('ccprdapp077')
$Servers += ,('ccprdapp082')
$Servers += ,('ccprdapp084')
$Servers += ,('ccprdapp089')
$Servers += ,('ccprdapp090')
$Servers += ,('ccprdapp091')
$Servers += ,('ccprdapp092')
$Servers += ,('ccprdapp093')
$Servers += ,('ccprdapp117')
$Servers += ,('ccprdapp118')
$Servers += ,('ccprdapp127')
$Servers += ,('ccprdapp211')
$Servers += ,('ccprdapp244')
$Servers += ,('ccprdapp280')
$Servers += ,('ccprdapp299')
$Servers += ,('ccprdapp306')
$Servers += ,('ccprdapp317')
$Servers += ,('ccprdapp324')
$Servers += ,('ccprdapp334')
$Servers += ,('ccprddb003')
$Servers += ,('ccprddb027')
$Servers += ,('ccprddb074')
$Servers += ,('ccprddb093')
$Servers += ,('ccprddb122')
$Servers += ,('ccprddb123')
$Servers += ,('ccprddb126')
$Servers += ,('ccprddb127')
$Servers += ,('ccprddb130')
$Servers += ,('ccprddb135')
$Servers += ,('ccprdwf032')
$Servers += ,('ccprdwf033')
$Servers += ,('ccprdwf066')
$Servers += ,('ccprdwf067')
$Servers += ,('ccprdwf071')


$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BLISPRD3 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10