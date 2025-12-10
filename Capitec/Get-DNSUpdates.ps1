$CSVs = get-childitem 'c:\temp\henri\SCCM\*.csv'
$Details = @()
ForEach ($CSV in $CSVs) {
    $Data = Import-Csv $CSV.FullName
    $Details += ,(New-Object -TypeName PSObject -Property @{
        Server = $Data.Server
        SCCMInstalled = $Data.SCCMInstalled
        SCCMAgentRunning = $Data.SCCMAgentRunning
        Result = $Data.Result
    })
    Remove-Variable Data
}
$Params = @("Server", "SCCMInstalled", "SCCMAgentRunning","Result")
$Details | Select-Object $Params | Out-GridView