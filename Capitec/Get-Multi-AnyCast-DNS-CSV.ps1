Function Get-CSVData {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Path
    )
    $CSVs = Get-ChildItem ($Path + '\*.csv')
    $Details = @()
    ForEach ($CSV in $CSVs) {
        $Data = Import-Csv $CSV.FullName
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Data.Server
            Adapter = $Data.Adapter
            OriginalDNSServers = $Data.OriginalDNSServers
            SetDNSServers = $Data.SetDNSServers
            Result = $Data.Result
        })
        Remove-Variable Data
    }
    Return $Details
}
$Folders = @()
$Folders += ,('C:\Temp\Henri\DNSUpdates-Anycast-QA')
$Details = @()
ForEach ($Path in $Folders) {
    $Results = Get-CSVData -Path $Path
    ForEach ($Result in $Results) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Result.Server
            Adapter = $Result.Adapter
            OriginalDNSServers = $Result.OriginalDNSServers
            SetDNSServers = $Result.SetDNSServers
            Result = $Result.Result
        })
    }
    Remove-Variable Results
    [GC]::Collect()
}
$Details | Select-Object Server, OriginalDNSServers, SetDNSServers, Result | Out-GridView #| Export-Csv main1.csv -Delimiter ';' -NoTypeInformation