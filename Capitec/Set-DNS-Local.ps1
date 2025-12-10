$DNSServers = @()
$DNSServers += ,("10.225.97.201")
$DNSServers += ,("10.225.97.202")
$DNSServers += ,("10.224.106.200")

# Define the DNS suffix search order
$DNSSuffixSearchOrder = @()
$DNSSuffixSearchOrder += ,("capitecbank.fin.sky")
$DNSSuffixSearchOrder += ,("linux.capinet")

$Details = @()

Try {

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
        Set-DnsClientGlobalSetting -SuffixSearchList $DNSSuffixSearchOrder
        $SetSuffixSearchOrder = (Get-DnsClientGlobalSetting).SuffixSearchList
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            Adapter = $Adapter
            OriginalDNSServers = $OriginalDNSServers
            SetDNSServers = $SetDNSServers
            OriginalSuffixSearchList = $OriginalSuffixSearchList
            SetSuffixSearchOrder = $SetSuffixSearchOrder
            Result = 'Success'
        })
    }
    Else {
        Write-Host ($env:Computernamer + ': ' + $Adapter.Count.ToString() + ' adapters found') -ForegroundColor Red
    }
}
Catch {
    $Details += ,(New-Object -TypeName PSObject -Property @{
        Server = $Server
        Adapter = $Adapter
        OriginalDNSServers = $OriginalDNSServers
        SetDNSServers = $SetDNSServers
        OriginalSuffixSearchList = $OriginalSuffixSearchList
        SetSuffixSearchOrder = $SetSuffixSearchOrder
        Result = $_
    })
}
$Details | Select-Object Server, Result, OriginalDNSServers, SetDNSServers, OriginalSuffixSearchList, SetSuffixSearchOrder, Adapter | Out-GridView