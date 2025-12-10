$CSVs = get-childitem 'C:\Temp\Henri\DNSHostsAudit3\*.csv'
$Details = @()
ForEach ($CSV in $CSVs) {
    [Object[]] $ImportedData = Import-Csv $CSV.FullName
    ForEach ($Data in $ImportedData) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Data.Server
            DHCPNameServer = $Data.DHCPNameServer
            NameServer = $Data.NameServer
            DHCPServerPublished = $Data.DHCPServerPublished
            DHCPInUse = $Data.DHCPInUse
            Hosts = $Data.Hosts
            IPAddress = $Data.IPAddress
            DHCPIPAddress = $Data.DHCPIPAddress
            Result = $Data.Result
        })
    }
    Remove-Variable Data
}
#@("Server", "DHCPNameServer", "NameServer", "DHCPServerPublished", "DHCPInUse", "Hosts", "IPAddress", "DHCPIPAddress", "Result")
$Details | Select-Object "Server","DHCPNameServer","NameServer","DHCPServerPublished","DHCPInUse","Hosts","IPAddress","DHCPIPAddress","Result" | Out-GridView
$Details | Select-Object "Server","Column","DHCPNameServer","NameServer","DHCPServerPublished","DHCPInUse","Hosts","IPAddress","DHCPIPAddress" | Export-CSV main33.csv -Delimiter ';' -NoTypeInformation