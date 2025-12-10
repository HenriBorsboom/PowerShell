Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; Start-Slep -Seconds 1 }
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
Function BLISDEV1 {
    $Servers = @()
    $Servers += ,('CBUTLDEV01')
    $Servers += ,('CBVMNDVAPW030')
    $Servers += ,('CBVMNDVAPW031')
    $Servers += ,('CBVMNDVAPW058')
    $Servers += ,('CBVMNDVDBW014')
    $Servers += ,('CBVMNDVDBW015')
    
    Return $Servers
}
Function BLISDEV2 {
    $Servers = @()
    $Servers += ,('CBWLNDVDBW128')
    $Servers += ,('CBWLNDVWFW089')
    $Servers += ,('CCDEVAPP334')
    $Servers += ,('CCDEVAPP336')
    $Servers += ,('CCDEVDB219')
    $Servers += ,('CCDEVWF067')
    
    Return $Servers
}
Function BLISQA1 {
    $Servers = @()
    $Servers += ,('CBWLNQAAPW169')
    $Servers += ,('CBWLNQADBW009')
    $Servers += ,('CBWLNQADBW013')
    $Servers += ,('CBWLNQADBW040')
    $Servers += ,('CBWLNQADBW082')
    $Servers += ,('CBWLNQADBW129')
    $Servers += ,('CBWLNQADBW143')
    $Servers += ,('CBWLNQADBW144')
    $Servers += ,('CBWLNQADBW158')
    $Servers += ,('CBWLNQADBW173')
    $Servers += ,('CBWLNQADBW186')
    $Servers += ,('CBWLNQADBW193')
    $Servers += ,('CBWLNQAWFW049')
    $Servers += ,('CBWLNQAWFW050')
    $Servers += ,('CBWLNQAWFW051')
    $Servers += ,('CBWLNQAWFW052')
    $Servers += ,('CBWLNQAWFW084')
    $Servers += ,('CCQAAPP032')
    $Servers += ,('CCQAAPP069')
    $Servers += ,('CCQAAPP184')
    $Servers += ,('CCQAAPP203')
    $Servers += ,('CCQADB029')
    $Servers += ,('CCQADB055')
    $Servers += ,('CCQADB058')
    $Servers += ,('CCQADB062')
    $Servers += ,('ccqadbcl08')
    $Servers += ,('ccqadbcl09')
    $Servers += ,('CCQAWF001')
    $Servers += ,('CCQAWF002')
    $Servers += ,('clscashdbqa01')
    $Servers += ,('clscgwqadb01')
    
    Return $Servers
}
Function BFTCQA1 {
    $Servers = @()
    $Servers += ,('CBVMNQAAPW002')
    $Servers += ,('CBVMNQADBW006')
    $Servers += ,('CBVMNQADBW008')
    
    Return $Servers
}
Function BFTCQA2 {
    $Servers = @()
    $Servers += ,('CBWLNQAAPW250')
    $Servers += ,('CBWLNQAAPW251')
    
    Return $Servers
}
    
#Example of Use
Clear-Host
$BLISDEV1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\DNSUpdates\BLISDEV1'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFoler -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.106.200")
    $DNSServers += ,("10.224.106.201")
    #$DNSServers += ,("10.224.106.200")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    Try {
        ('Invoking command on' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -ScriptBlock {
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
                Write-Host ($env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
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
}
$BLISDEV2 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\DNSUpdates\BLISDEV2'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFolder -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.106.201")
    $DNSServers += ,("10.224.106.200")
    #$DNSServers += ,("10.224.106.200")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    Try {
        ('Invoking command on' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -ScriptBlock {
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
                Write-Host ($env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
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
}
$BLISQA1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\DNSUpdates\BLISQA1'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFolder -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.224.106.201")
    $DNSServers += ,("10.224.106.200")
    #$DNSServers += ,("10.225.97.202")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    Try {
        ('Invoking command on' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -ScriptBlock {
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
                Write-Host ($env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
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
}
$BFTCQA1 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\DNSUpdates\BFTCQA1'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFolder -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.225.97.221")
    $DNSServers += ,("10.225.97.220")
    $DNSServers += ,("10.225.97.202")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    Try {
        ('Invoking command on' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -ScriptBlock {
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
                Write-Host ($env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
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
}
$BFTCQA2 = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\DNSUpdates\BFTCQA2'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFolder -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    # Define the DNS servers to be assigned
    $DNSServers = @()
    $DNSServers += ,("10.225.97.220")
    $DNSServers += ,("10.225.97.202")
    $DNSServers += ,("10.225.97.201")

    # Define the DNS suffix search order
    $DNSSuffixSearchOrder = @()
    $DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
    $DNSSuffixSearchOrder += ,("linux.capinet")

    $Details = @()
    Try {
        ('Invoking command on' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ArgumentList $DNSServers, $dnsSuffixSearchOrder -ScriptBlock {
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
                Write-Host ($env:Computername + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
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
}

#$Credential = Get-Credential
#region Servers

#endregion

#$SBArgs = @($Credential)
$Servers = BLISDEV1; Start-Jobs -ScriptBlock $BLISDEV1 -Targets $Servers -PassTargetToScriptBlock TargetOnly -MaximumJobs 10
$Servers = BLISDEV2; Start-Jobs -ScriptBlock $BLISDEV2 -Targets $Servers -PassTargetToScriptBlock TargetOnly -MaximumJobs 10
$Servers = BLISQA1; Start-Jobs -ScriptBlock $BLISQA1 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = BFTCQA1; Start-Jobs -ScriptBlock $BFTCQA1 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = BFTCQA2; Start-Jobs -ScriptBlock $BFTCQA2 -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
