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
$BLISPRD2 = {
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
    $DNSServers += ,("10.224.97.220")
    $DNSServers += ,("10.224.97.221")
    $DNSServers += ,("10.225.97.220")

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
$Servers += ,('CBWLPPRAPW039')
$Servers += ,('CBWLPPRAPW047')
$Servers += ,('CBWLPPRAPW050')
$Servers += ,('CBWLPPRAPW053')
$Servers += ,('CBWLPPRAPW054')
$Servers += ,('CBWLPPRAPW055')
$Servers += ,('CBWLPPRAPW056')
$Servers += ,('CBWLPPRAPW057')
$Servers += ,('CBWLPPRAPW058')
$Servers += ,('CBWLPPRAPW060')
$Servers += ,('CBWLPPRAPW061')
$Servers += ,('CBWLPPRAPW076')
$Servers += ,('CBWLPPRAPW077')
$Servers += ,('CBWLPPRAPW097')
$Servers += ,('CBWLPPRAPW098')
$Servers += ,('CBWLPPRAPW100')
$Servers += ,('CBWLPPRAPW109')
$Servers += ,('CBWLPPRAPW111')
$Servers += ,('CBWLPPRAPW120')
$Servers += ,('CBWLPPRAPW123')
$Servers += ,('CBWLPPRAPW128')
$Servers += ,('CBWLPPRAPW131')
$Servers += ,('CBWLPPRAPW133')
$Servers += ,('CBWLPPRAPW135')
$Servers += ,('CBWLPPRAPW137')
$Servers += ,('CBWLPPRAPW146')
$Servers += ,('CBWLPPRAPW150')
$Servers += ,('CBWLPPRAPW155')
$Servers += ,('CBWLPPRAPW157')
$Servers += ,('CBWLPPRAPW158')
$Servers += ,('CBWLPPRAPW162')
$Servers += ,('CBWLPPRAPW166')
$Servers += ,('CBWLPPRAPW168')
$Servers += ,('CBWLPPRAPW185')
$Servers += ,('CBWLPPRAPW212')
$Servers += ,('CBWLPPRAPW215')
$Servers += ,('CBWLPPRAPW216')
$Servers += ,('CBWLPPRAPW218')
$Servers += ,('CBWLPPRAPW219')
$Servers += ,('CBWLPPRAPW224')
$Servers += ,('CBWLPPRAPW225')
$Servers += ,('CBWLPPRAPW226')
$Servers += ,('CBWLPPRAPW229')
$Servers += ,('CBWLPPRAPW230')
$Servers += ,('CBWLPPRAPW232')
$Servers += ,('CBWLPPRAPW233')
$Servers += ,('CBWLPPRAPW236')
$Servers += ,('CBWLPPRAPW240')
$Servers += ,('CBWLPPRAPW241')
$Servers += ,('CBWLPPRAPW244')
$Servers += ,('CBWLPPRAPW253')
$Servers += ,('CBWLPPRAPW258')
$Servers += ,('CBWLPPRAPW274')
$Servers += ,('CBWLPPRAPW278')
$Servers += ,('CBWLPPRAPW282')
$Servers += ,('CBWLPPRAPW283')
$Servers += ,('CBWLPPRAPW289')
$Servers += ,('CBWLPPRAPW336')
$Servers += ,('CBWLPPRDBW003')
$Servers += ,('CBWLPPRDBW004')
$Servers += ,('CBWLPPRDBW012')
$Servers += ,('CBWLPPRDBW024')
$Servers += ,('CBWLPPRDBW032')
$Servers += ,('CBWLPPRDBW035')
$Servers += ,('CBWLPPRDBW039')
$Servers += ,('CBWLPPRDBW052')
$Servers += ,('CBWLPPRDBW060')
$Servers += ,('CBWLPPRDBW064')
$Servers += ,('CBWLPPRDBW066')
$Servers += ,('CBWLPPRDBW067')
$Servers += ,('CBWLPPRDBW076')
$Servers += ,('CBWLPPRDBW089')
$Servers += ,('CBWLPPRDBW090')
$Servers += ,('CBWLPPRDBW102')
$Servers += ,('CBWLPPRDBW144')
$Servers += ,('CBWLPPRDBW145')
$Servers += ,('CBWLPPRDBW166')
$Servers += ,('CBWLPPRDBW168')
$Servers += ,('CBWLPPRDBW178')
$Servers += ,('CBWLPPRDBW179')
$Servers += ,('CBWLPPRDBW180')
$Servers += ,('CBWLPPRWFW005')
$Servers += ,('CBWLPPRWFW006')
$Servers += ,('CBWLPPRWFW024')
$Servers += ,('CBWLPPRWFW025')
$Servers += ,('CBWLPPRWFW026')
$Servers += ,('CBWLPPRWFW027')
$Servers += ,('CBWLPPRWFW039')
$Servers += ,('CCPRDAPP213')
$Servers += ,('CCPRDAPP305')
$Servers += ,('CCPRDDB001')
$Servers += ,('CCPRDDB017')
$Servers += ,('CCPRDDB053')
$Servers += ,('cbvmpprapw004')
$Servers += ,('cbvmpprapw010')
$Servers += ,('cbvmpprapw011')
$Servers += ,('cbvmpprapw015')
$Servers += ,('cbvmpprapw016')
$Servers += ,('cbvmpprapw017')
$Servers += ,('cbvmpprapw019')
$Servers += ,('cbvmpprapw020')
$Servers += ,('cbvmpprapw117')
$Servers += ,('cbvmpprapw136')
$Servers += ,('cbvmpprdbw002')
$Servers += ,('cbvmpprdbw003')
$Servers += ,('cbvmpprdbw004')
$Servers += ,('cbwlddrapw165')
$Servers += ,('cbwlpprapw323')
$Servers += ,('cbwlpprapw324')
$Servers += ,('cbwlpprapw325')
$Servers += ,('cbwlpprapw326')
$Servers += ,('cbwlpprapw355')
$Servers += ,('cbwlpprapw356')
$Servers += ,('cbwlpprapw360')
$Servers += ,('cbwlpprapw361')
$Servers += ,('cbwlpprapw373')
$Servers += ,('cbwlpprapw382')


$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BLISPRD2 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10