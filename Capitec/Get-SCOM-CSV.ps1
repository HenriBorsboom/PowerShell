

$CSVs = get-childitem 'C:\Temp\Henri\SCOM\*.csv'
$Details = @()
ForEach ($CSV in $CSVs) {
    $Data = Import-Csv $CSV.FullName -Delimiter ';'
    $Details += ,(New-Object -TypeName PSObject -Property @{
        Server = $Data.Server
        Installed = $Data.Installed
        ServiceInstalled = $Data.ServiceInstalled
        ServiceRunning = $Data.ServiceRunning
        Status = $Data.Status
    })
    Remove-Variable Data
}
$Details | Out-GridView