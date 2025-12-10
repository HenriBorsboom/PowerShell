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
$BFTCNPRD2 = {
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
    $DNSServers += ,("10.225.97.221")
    $DNSServers += ,("10.225.97.220")
    $DNSServers += ,("10.224.106.201")

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
$Servers += ,('CBWLNQAWFW012')
$Servers += ,('CBWLNQAWFW014')
$Servers += ,('CBWLNQAWFW015')
$Servers += ,('CBWLNQAWFW016')
$Servers += ,('CBWLNQAWFW026')
$Servers += ,('CBWLNQAWFW027')
$Servers += ,('CBWLNQAWFW030')
$Servers += ,('CCQADB043')
$Servers += ,('CCQADB075')
$Servers += ,('CCQADB082')
$Servers += ,('CCQADB093')
$Servers += ,('cbmftqa01')
$Servers += ,('cbpostdev02')
$Servers += ,('cbtermqa01')
$Servers += ,('cbvmndvdbw045')
$Servers += ,('cbvmndvdbw052')
$Servers += ,('cbvmnqaapw002')
$Servers += ,('cbvmnqadbw003')
$Servers += ,('cbvmnqadbw004')
$Servers += ,('cbvmnqadbw005')
$Servers += ,('cbvmnqadbw017')
$Servers += ,('cbvmnqawfw001')
$Servers += ,('cbvmnqawfw003')
$Servers += ,('cbvmnqawfw005')
$Servers += ,('cbwlnqaapw174')
$Servers += ,('cbwlnqaapw175')
$Servers += ,('cbwlnqaapw179')
$Servers += ,('cbwlnqaapw184')
$Servers += ,('cbwlnqaapw185')
$Servers += ,('cbwlnqaapw186')
$Servers += ,('cbwlnqaapw187')
$Servers += ,('cbwlnqaapw188')
$Servers += ,('cbwlnqaapw192')
$Servers += ,('cbwlnqaapw195')
$Servers += ,('cbwlnqaapw198')
$Servers += ,('cbwlnqaapw202')
$Servers += ,('cbwlnqaapw243')
$Servers += ,('cbwlnqaapw245')
$Servers += ,('cbwlnqaapw246')
$Servers += ,('cbwlnqaapw247')
$Servers += ,('cbwlnqaapw250')
$Servers += ,('cbwlnqaapw251')
$Servers += ,('cbwlnqadbw099')
$Servers += ,('cbwlnqadbw100')
$Servers += ,('cbwlnqadbw107')
$Servers += ,('cbwlnqadbw109')
$Servers += ,('cbwlnqadbw111')
$Servers += ,('cbwlnqadbw121')
$Servers += ,('cbwlnqadbw123')
$Servers += ,('cbwlnqadbw141')
$Servers += ,('cbwlnqadbw142')
$Servers += ,('cbwlnqadbw150')
$Servers += ,('cbwlnqadbw156')
$Servers += ,('cbwlnqadbw157')
$Servers += ,('cbwlnqadbw172')
$Servers += ,('cbwlnqawfw065')
$Servers += ,('cbwlnqawfw066')
$Servers += ,('cbwlnqawfw067')
$Servers += ,('cbwlnqawfw068')
$Servers += ,('cbwlnqawfw069')
$Servers += ,('cbwlnqawfw070')
$Servers += ,('cbwlnqawfw072')
$Servers += ,('cbwlnqawfw075')
$Servers += ,('cbwlnqawfw088')
$Servers += ,('cbwlnqawfw089')
$Servers += ,('cbwlpprapw643')
$Servers += ,('cbwlpprapw645')
$Servers += ,('cbwlpprapw646')
$Servers += ,('ccqaapp080')
$Servers += ,('ccqaapp083')
$Servers += ,('ccqaapp084')
$Servers += ,('ccqaapp218')
$Servers += ,('ccqaapp219')
$Servers += ,('ccqaapp239')
$Servers += ,('ccqaapp240')
$Servers += ,('ccqadb003')
$Servers += ,('ccqadb041')
$Servers += ,('ccqadb072')
$Servers += ,('ccqadb126')
$Servers += ,('ccqawf011')
$Servers += ,('ccqawf023')
$Servers += ,('ccqawf031')
$Servers += ,('ccqawf043')


$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BFTCNPRD2 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10