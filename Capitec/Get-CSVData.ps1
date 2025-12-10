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
            Result = $Data.Result
        })
        Remove-Variable Data
    }
    Return $Details
}
$Folders = @()
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCINT1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCNP1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCNP2')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCQA1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCQA2')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCQA3')
$Folders += ,('C:\temp\Henri\DNSUpdates\BFTCQA4')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISINT1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISINT2')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISNP1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISNP2')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISQA1')
$Folders += ,('C:\temp\Henri\DNSUpdates\BLISQA2')

$Details = @()
ForEach ($Path in $Folders) {
    $Results = Get-CSVData -Path $Path
    ForEach ($Result in $Results) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Result.Server
            Result = $Result.Result
        })
    }
    Remove-Variable Results
    [GC]::Collect()
}
$Details | Select-Object Server, Result | Out-GridView