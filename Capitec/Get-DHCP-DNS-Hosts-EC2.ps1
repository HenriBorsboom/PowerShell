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
Function AWSDEV {
$Servers = @()
$Servers += ,('CBCOMMSDEV')
$Servers += ,('CBVMNDVAPW112')
$Servers += ,('CBVMNDVAPW137')
$Servers += ,('WDATLASRADB1')
$Servers += ,('WDATLASRATAPP1')
$Servers += ,('WDATLASRATAPP2')
$Servers += ,('WDCASHSUIMQX01')
$Servers += ,('WDCASHSUIMQX02')
$Servers += ,('WDCASHSUVVQX01')
$Servers += ,('WDCASHSUVVQX02')
$Servers += ,('WDCLDDPSDKERB')
$Servers += ,('WDGSERVFADP01')
$Servers += ,('WDINSURADCASTG')
$Servers += ,('WDINSURADCA')
$Servers += ,('WDINSURAINSCLM')
$Servers += ,('WDISAENGSALEP1')
$Servers += ,('WDISAENGSALEP2')
$Servers += ,('WDOPLNP1CNECT2')
$Servers += ,('WDOPLNP1LBTEST')
$Servers += ,('WDOPLNP1WIN002')
$Servers += ,('WDPAYDATWIPDAT')
$Servers += ,('WDPAYDATWQPDAT')
$Servers += ,('WDPAYHCPNPS01')
$Servers += ,('WDPLBCRDINSAWS')
$Servers += ,('WDPLBCRDOBAPI')
$Servers += ,('WDPLBCRDOBPRC')
$Servers += ,('WDPLBCRDOBUI1')
$Servers += ,('WDPLBCRDOBWEB')
$Servers += ,('WDPLDRINTANSPL1')
$Servers += ,('WDPLIPLACTMAGT')
$Servers += ,('WDPLIPLAINSCLA')
$Servers += ,('WDPLRCLSBMGTD1')
$Servers += ,('WDPLRCLSBSTRD1')
$Servers += ,('WDPLRCLSBSTRD2')
$Servers += ,('WDPLRCLSBVSTD1')
$Servers += ,('WDPLRCLSBVSTD2')
$Servers += ,('WDPLRDOCWF03')
$Servers += ,('WDPLRDOCWF04')
$Servers += ,('WDPLRDOCWF05')
$Servers += ,('WDPLSCLEVRDEMO')
$Servers += ,('WDPLSDOGAPPDV1')
$Servers += ,('WDPLSDOGDBV1')
$Servers += ,('WDPLSFRDPAGW')
$Servers += ,('WDPLSOBSOBSWIN')
$Servers += ,('WDPLSPAYDCDD01')
$Servers += ,('WDPLSPAYDCSD01')
$Servers += ,('WDPLSPAYEFTS1')
$Servers += ,('WDPLSPAYEFTS2')
$Servers += ,('WDPLSPAYSQLDV1')
$Servers += ,('WDRCREDITCBA007')
$Servers += ,('WDRCREDITCBA008')
$Servers += ,('WDTSCBRBBCDB1')
$Servers += ,('WDTSCBRBBCDB8')
$Servers += ,('WDVASPRJJUMPBX')
$Servers += ,('CCDEVWF083')
Return $Servers
}
Function AWSINT {
$Servers = @()
$Servers += ,('CBVMNITAPW037')
$Servers += ,('WICASHSUSDM01')
$Servers += ,('WIPLBCRDOBAPI1')
$Servers += ,('WIPLBCRDOBAPI2')
$Servers += ,('WIPLBCRDOBPRC1')
$Servers += ,('WIPLBCRDOBPRC2')
$Servers += ,('WIPLBCRDOBUI1')
$Servers += ,('WIPLBCRDOBUI2')
$Servers += ,('WIPLBCRDOBWEB1')
$Servers += ,('WIPLBCRDOBWEB2')
$Servers += ,('WIPLIPLAINSCLA')
$Servers += ,('WIPLRCLSBMGTI1')
$Servers += ,('WIPLRCLSBSTRI1')
$Servers += ,('WIPLRCLSBSTRI2')
$Servers += ,('WIPLRCLSBVSTI1')
$Servers += ,('WIPLRCLSBVSTI2')
$Servers += ,('WIPLRDOCWFINT1')
$Servers += ,('WIPLRDOCWFINT2')
$Servers += ,('WIPLRDOCWFINT3')
$Servers += ,('WIPLSPAYDCDI01')
$Servers += ,('WIPLSPAYDCSI01')
Return $Servers
}
Function AWSQA {
$Servers = @()
$Servers += ,('CBVMNQADBW020')
$Servers += ,('CBVMNQADBW021')
$Servers += ,('CBVMNQADBW022')
$Servers += ,('WQCASHSUSDM01')
$Servers += ,('WQCASHSUSS02')
$Servers += ,('WQCLDDPSDRGBQA')
$Servers += ,('WQCLDDPSDRGT')
$Servers += ,('WQPAYHCPNPS01')
$Servers += ,('WQPAYHCPNPS02')
$Servers += ,('WQPAYHCPWQWF01')
$Servers += ,('WQPAYHCPWQWF02')
$Servers += ,('WQPLBCRDOBAPI1')
$Servers += ,('WQPLBCRDOBAPI2')
$Servers += ,('WQPLBCRDOBPRC1')
$Servers += ,('WQPLBCRDOBPRC2')
$Servers += ,('WQPLBCRDOBUI1')
$Servers += ,('WQPLBCRDOBUI2')
$Servers += ,('WQPLBCRDOBWEB1')
$Servers += ,('WQPLBCRDOBWEB2')
$Servers += ,('WQPLIPLACTMAGT')
$Servers += ,('WQPLIPLAINSCLA')
$Servers += ,('WQPLRCLSBMGTQ1')
$Servers += ,('WQPLRCLSBSTRQ1')
$Servers += ,('WQPLRCLSBSTRQ2')
$Servers += ,('WQPLRCLSBVSTQ1')
$Servers += ,('WQPLRCLSBVSTQ2')
$Servers += ,('WQPLRCLSBVSTQ3')
$Servers += ,('WQPLRCLSBVSTQ4')
$Servers += ,('WQPLRDOCWFQA1')
$Servers += ,('WQPLRDOCWFQA2')
$Servers += ,('WQPLRDOCWFQA3')
$Servers += ,('WQPLSPAYDCDQ02')
$Servers += ,('WQPLSPAYDCDQ03')
$Servers += ,('WQPLSPAYDCDQ04')
$Servers += ,('WQPLSPAYDCDQ06')
$Servers += ,('WQPLSPAYDCSQ01')
$Servers += ,('WQPLSPAYDCSQ02')
$Servers += ,('WQPLSPAYEFTQA1')
$Servers += ,('WQPLSPAYEFTQA2')
$Servers += ,('WQTSCBRBWQSJ01')
Return $Servers
}
#Example of Use
Clear-Host
$EC2DNSHostSettings = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\EC2DNSHostChecks1\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\EC2DNSHostChecks1\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

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

#$Credential = Get-Credential

$SBArgs = @($Credential)
$Servers = AWSDEV; Start-Jobs -ScriptBlock $EC2DNSHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = AWSINT; Start-Jobs -ScriptBlock $EC2DNSHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = AWSQA; Start-Jobs -ScriptBlock $EC2DNSHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10