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
$BLISNPRD2 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSUpdates1\BLIS Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSUpdates1\BLIS Non Prod - ' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.106.201")
    $DNSServers += ,("10.224.106.200")
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
$Servers += ,('CBWLNQAAPW035')
$Servers += ,('CBWLNQAAPW085')
$Servers += ,('CBWLNQAAPW109')
$Servers += ,('CBWLNQAAPW138')
$Servers += ,('CBWLNQADBW003')
$Servers += ,('CBWLNQADBW009')
$Servers += ,('CBWLNQADBW013')
$Servers += ,('CBWLNQADBW040')
$Servers += ,('CBWLNQADBW074')
$Servers += ,('CBWLNQADBW082')
$Servers += ,('CCDEVDB010')
$Servers += ,('CCINTDB006')
$Servers += ,('CCINTDB019')
$Servers += ,('CCINTDB025')
$Servers += ,('CCINTDB027')
$Servers += ,('cbvmndvdbw013')
$Servers += ,('cbvmndvdbw014')
$Servers += ,('cbvmndvdbw015')
$Servers += ,('cbvmndvdbw017')
$Servers += ,('cbvmndvdbw044')
$Servers += ,('cbvmndvdbw050')
$Servers += ,('cbvmndvdbw051')
$Servers += ,('cbvmndvwfw013')
$Servers += ,('cbvmnitapw003')
$Servers += ,('cbvmnitwfw001')
$Servers += ,('cbvmnitwfw002')
$Servers += ,('cbvmnitwfw003')
$Servers += ,('cbvmnqaapw003')
$Servers += ,('cbvmnqaapw011')
$Servers += ,('cbwlndvapw417')
$Servers += ,('cbwlndvapw450')
$Servers += ,('cbwlndvapw454')
$Servers += ,('cbwlndvapw474')
$Servers += ,('cbwlndvapw478')
$Servers += ,('cbwlndvapw482')
$Servers += ,('cbwlndvapw483')
$Servers += ,('cbwlndvapw486')
$Servers += ,('cbwlndvapw493')
$Servers += ,('cbwlndvapw494')
$Servers += ,('cbwlndvapw496')
$Servers += ,('cbwlndvapw504')
$Servers += ,('cbwlndvapw505')
$Servers += ,('cbwlndvapw507')
$Servers += ,('cbwlndvapw508')
$Servers += ,('cbwlndvapw509')
$Servers += ,('cbwlndvapw515')
$Servers += ,('cbwlndvapw524')
$Servers += ,('cbwlndvapw533')
$Servers += ,('cbwlndvapw547')
$Servers += ,('cbwlndvapw551')
$Servers += ,('cbwlndvapw585')
$Servers += ,('cbwlndvapw624')
$Servers += ,('cbwlndvapw651')
$Servers += ,('cbwlndvapw654')
$Servers += ,('cbwlndvapw669')
$Servers += ,('cbwlndvapw674')
$Servers += ,('cbwlndvapw680')
$Servers += ,('cbwlndvapw682')
$Servers += ,('cbwlndvdbw140')
$Servers += ,('cbwlndvdbw162')
$Servers += ,('cbwlndvdbw225')
$Servers += ,('cbwlndvdbw249')
$Servers += ,('cbwlndvdbw258')
$Servers += ,('cbwlndvdbw276')
$Servers += ,('cbwlndvdbw288')
$Servers += ,('cbwlndvdbw319')
$Servers += ,('cbwlndvdbw346')
$Servers += ,('cbwlndvdbw350')
$Servers += ,('cbwlndvdbw359')
$Servers += ,('cbwlndvdbw402')
$Servers += ,('cbwlndvdbw429')
$Servers += ,('cbwlndvdbw448')
$Servers += ,('cbwlndvdbw459')
$Servers += ,('cbwlndvdbw460')
$Servers += ,('cbwlndvdbw461')
$Servers += ,('cbwlndvwfw085')
$Servers += ,('cbwlndvwfw088')
$Servers += ,('cbwlndvwfw089')
$Servers += ,('cbwlndvwfw096')
$Servers += ,('cbwlndvwfw097')
$Servers += ,('cbwlndvwfw100')
$Servers += ,('cbwlndvwfw106')
$Servers += ,('cbwlndvwfw107')
$Servers += ,('cbwlndvwfw109')
$Servers += ,('cbwlndvwfw110')
$Servers += ,('cbwlndvwfw111')
$Servers += ,('cbwlnitapw050')
$Servers += ,('cbwlnitapw051')
$Servers += ,('cbwlnitapw063')
$Servers += ,('cbwlnitapw064')
$Servers += ,('cbwlnitapw065')
$Servers += ,('cbwlnitapw101')
$Servers += ,('cbwlnitapw102')
$Servers += ,('cbwlnitapw114')
$Servers += ,('cbwlnitdbw069')
$Servers += ,('cbwlnitdbw070')
$Servers += ,('cbwlnitdbw077')
$Servers += ,('cbwlnitdbw078')
$Servers += ,('cbwlnitdbw085')
$Servers += ,('cbwlnitdbw086')
$Servers += ,('cbwlnitdbw121')
$Servers += ,('cbwlnitdbw132')
$Servers += ,('cbwlnitdbw136')
$Servers += ,('cbwlnitdbw139')
$Servers += ,('cbwlnitwfw036')
$Servers += ,('cbwlnitwfw039')
$Servers += ,('cbwlnitwfw040')
$Servers += ,('cbwlnitwfw041')
$Servers += ,('cbwlnitwfw043')
$Servers += ,('cbwlnitwfw047')
$Servers += ,('cbwlnitwfw052')
$Servers += ,('cbwlnitwfw054')
$Servers += ,('cbwlnitwfw055')
$Servers += ,('cbwlnqaapw169')
$Servers += ,('cbwlnqaapw177')
$Servers += ,('cbwlnqadbw129')
$Servers += ,('cbwlnqadbw143')
$Servers += ,('cbwlnqadbw144')
$Servers += ,('cbwlnqadbw158')
$Servers += ,('cbwlnqadbw169')
$Servers += ,('cbwlnqadbw173')
$Servers += ,('cbwlnqadbw193')
$Servers += ,('cbwlnqawfw049')
$Servers += ,('cbwlnqawfw050')
$Servers += ,('cbwlnqawfw051')
$Servers += ,('cbwlnqawfw052')
$Servers += ,('cbwlnqawfw064')
$Servers += ,('cbwlnqawfw084')
$Servers += ,('ccdevapp166')
$Servers += ,('ccdevapp168')
$Servers += ,('ccdevapp169')
$Servers += ,('ccdevapp170')
$Servers += ,('ccdevapp334')
$Servers += ,('ccdevapp335')
$Servers += ,('ccdevapp336')
$Servers += ,('ccdevapp363')
$Servers += ,('ccdevapp394')
$Servers += ,('ccdevapp399')
$Servers += ,('ccdevapp416')
$Servers += ,('ccdevapp448')
$Servers += ,('ccdevapp449')
$Servers += ,('ccdevdb025')
$Servers += ,('ccdevdb036')
$Servers += ,('ccdevdb044')
$Servers += ,('ccdevdb062')
$Servers += ,('ccdevdb091')
$Servers += ,('ccdevdb095')
$Servers += ,('ccdevdb101')
$Servers += ,('ccdevdb126')
$Servers += ,('ccdevdb127')
$Servers += ,('ccdevdb183')
$Servers += ,('ccdevdb189')
$Servers += ,('ccdevdb192')
$Servers += ,('ccdevdb198')
$Servers += ,('ccdevdb199')
$Servers += ,('ccdevdb202')
$Servers += ,('ccdevdb208')
$Servers += ,('ccdevdb219')
$Servers += ,('ccdevdb221')
$Servers += ,('ccdevdb238')
$Servers += ,('ccdevdb240')
$Servers += ,('ccdevdb247')
$Servers += ,('ccdevdb248')
$Servers += ,('ccdevwf019')
$Servers += ,('ccdevwf035')
$Servers += ,('ccdevwf040')
$Servers += ,('ccdevwf043')
$Servers += ,('ccdevwf059')
$Servers += ,('ccdevwf066')
$Servers += ,('ccdevwf067')
$Servers += ,('ccdevwf082')
$Servers += ,('ccintapp010')
$Servers += ,('ccintapp021')
$Servers += ,('ccintapp054')
$Servers += ,('ccintapp055')
$Servers += ,('ccintapp064')
$Servers += ,('ccintapp065')
$Servers += ,('ccintdb003')
$Servers += ,('ccintdb005')
$Servers += ,('ccintdb007')
$Servers += ,('ccintdb008')
$Servers += ,('ccintdb026')
$Servers += ,('ccintwf010')
$Servers += ,('ccprdapp331')
$Servers += ,('ccqaapp184')
$Servers += ,('ccqaapp188')
$Servers += ,('ccqaapp203')
$Servers += ,('ccqadb055')
$Servers += ,('ccqadb058')
$Servers += ,('ccqadb061')
$Servers += ,('ccqadb062')
$Servers += ,('CBDBNDVDBW006')
$Servers += ,('CBDBNDVDBW013')
$Servers += ,('CBDBNDVDBW014')
$Servers += ,('CBDBNDVDBW017')
$Servers += ,('CBDBNDVDBW028')
$Servers += ,('CBDBNDVDBW031')
$Servers += ,('CBDBNDVDBW047')
$Servers += ,('CBDBNDVDBW059')
$Servers += ,('CBDBNDVDBW061')
$Servers += ,('CBDBNITDBW002')
$Servers += ,('CBDBNITDBW003')
$Servers += ,('CBDBNITDBW006')
$Servers += ,('CBDBNITDBW007')
$Servers += ,('CBDBNITDBW015')
$Servers += ,('CBDBNITDBW016')
$Servers += ,('CBDBNITDBW018')
$Servers += ,('CBDBNITDBW026')
$Servers += ,('CBDBNQADBW038')
$Servers += ,('CBDBNQADBW044')
$Servers += ,('CBDC001')
$Servers += ,('CBDC007')
$Servers += ,('CBDMDBINT01')


$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $BLISNPRD2 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10