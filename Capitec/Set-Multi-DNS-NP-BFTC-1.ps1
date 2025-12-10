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
$BFTCNPRD1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates1\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates1\BFTC Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.225.97.220")
    $DNSServers += ,("10.225.97.221")
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

#$Credential = Get-Credential
$Servers = @()
$Servers += ,('cbvmndvapw092')
$Servers += ,('cbvmndvapw114')
$Servers += ,('cbvmnqaapw016')
$Servers += ,('cbvmnqaapw022')
$Servers += ,('cbvmnqaapw023')
$Servers += ,('cbvmnqaapw024')
$Servers += ,('cbvmnqaapw032')
$Servers += ,('cbvmnqaapw033')
$Servers += ,('cbvmnqadbw006')
$Servers += ,('cbvmnqadbw008')
$Servers += ,('cbvmnqadbw013')
$Servers += ,('cbvmnqadbw014')
$Servers += ,('cbvmnqadbw024')
$Servers += ,('cbvmnqawfw009')
$Servers += ,('cbvmnqawfw010')
$Servers += ,('cbvmpprapw025')
$Servers += ,('cbvmpprdbw006')
$Servers += ,('cbvmpprdbw007')
$Servers += ,('CB0244')
$Servers += ,('CB0268')
$Servers += ,('CB0286')
$Servers += ,('CBBLVDMCSQA01')
$Servers += ,('CBBLVDMTCQA')
$Servers += ,('CBDMASQA01')
$Servers += ,('CBDMDBQA01')
$Servers += ,('CBDXCPQA01')
$Servers += ,('CBDXMSQA01')
$Servers += ,('CBWLNQAAPW012')
$Servers += ,('CBWLNQAAPW094')
$Servers += ,('CBWLNQAAPW095')
$Servers += ,('CBWLNQAAPW130')
$Servers += ,('CBWLNQAAPW131')
$Servers += ,('CBWLNQAAPW143')
$Servers += ,('CBWLNQAWFW028')
$Servers += ,('ccqaapp012')
$Servers += ,('ccqaapp026')
$Servers += ,('ccqaapp027')
$Servers += ,('ccqaapp158')
$Servers += ,('ccqaapp234')
$Servers += ,('ccqaapp235')
$Servers += ,('ccqadb059')
$Servers += ,('ccqadb142')
$Servers += ,('ccqadb153')
$Servers += ,('ccqawf050')
$Servers += ,('ccqawf051')
$Servers += ,('CBDBNQADBW002')
$Servers += ,('CBDBNQADBW009')
$Servers += ,('CBDBNQADBW010')
$Servers += ,('CBDBNQADBW011')
$Servers += ,('CBDBNQADBW018')
$Servers += ,('CBDBNQADBW035')
$Servers += ,('CBDBNQADBW041')
$Servers += ,('CBPORTINT02')
$Servers += ,('CBPORTQA02')
$Servers += ,('CBPOSTINT02')
$Servers += ,('CBPOSTQA02')
$Servers += ,('CBWLNDVDBW085')
$Servers += ,('CBWLNQAAPW013')
$Servers += ,('CBWLNQAAPW014')
$Servers += ,('CBWLNQAAPW087')
$Servers += ,('CBWLNQAAPW091')
$Servers += ,('CBWLNQAAPW092')
$Servers += ,('CBWLNQAAPW093')
$Servers += ,('CBWLNQAAPW105')
$Servers += ,('CBWLNQAAPW134')
$Servers += ,('CBWLNQADBW014')
$Servers += ,('CBWLNQADBW015')
$Servers += ,('CBWLNQADBW018')
$Servers += ,('CBWLNQADBW019')
$Servers += ,('CBWLNQADBW020')
$Servers += ,('CBWLNQADBW023')
$Servers += ,('CBWLNQADBW025')
$Servers += ,('CBWLNQADBW027')
$Servers += ,('CBWLNQADBW042')
$Servers += ,('CBWLNQADBW075')
$Servers += ,('CBWLNQAWFW001')
$Servers += ,('CBWLNQAWFW002')
$Servers += ,('CBWLNQAWFW003')
$Servers += ,('CBWLNQAWFW004')
$Servers += ,('CBWLNQAWFW005')
$Servers += ,('CBWLNQAWFW006')
$Servers += ,('CBWLNQAWFW010')
$Servers += ,('CBWLNQAWFW011')

$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BFTCNPRD1 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10