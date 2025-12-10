$ErrorActionPreference = 'Stop'

#$Credential = Get-Credential
Function Set-BFTC-NPRD {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Servers
    )
    
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
    For ($i = 0; $i -lt $Servers.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
        Try {
            $Result = Invoke-Command -ComputerName $servers[$i] -ArgumentList $DNSServers, $dnsSuffixSearchOrder -Credential $Credential -ScriptBlock {
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
                    Write-Host ($Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
                }
                Return $Adapter, $OriginalDNSServers, $SetDNSServers, $OriginalSuffixSearchList, $SetSuffixSearchOrder
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
                Result = 'Success'
            })
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                Adapter = $Result[0]
                OriginalDNSServers = $Result[1]
                SetDNSServers = $Result[2]
                OriginalSuffixSearchList = $Result[3]
                SetSuffixSearchOrder = $Result[4]
                Result = $_
            })
            Write-Host $_ -ForegroundColor Red
        }
    }
    $Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, OriginalSuffixSearchList, SetSuffixSearchOrder, Adapter | Out-GridView
    $Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, OriginalSuffixSearchList, SetSuffixSearchOrder, Adapter | Export-CSV ('C:\Temp\Henri\BFTC Non Prod - ' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv') -Delimiter ',' -NoTypeInformation
}