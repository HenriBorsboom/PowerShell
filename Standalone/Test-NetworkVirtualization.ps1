$Servers = @(
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

$HNVResults = @()

ForEach ($Server in $Servers) {
    #Write-Host $Server -ForegroundColor Green
    $ServerResults = New-Object PSObject -Property @{
        "Server"                     = $Server;
        "Customer Routes"            = (Get-NetVirtualizationCustomerRoute -CimSession $Server).Count;
        "Global Use External Router" = (Get-NetVirtualizationGlobal -CimSession $Server).UseExternalRouter;
        "Lookup Records"             = (Get-NetVirtualizationLookupRecord -CimSession $Server).Count;
        "Provider Addresses"         = (Get-NetVirtualizationProviderAddress -CimSession $Server).Count;
        "Provider Route"             = (Get-NetVirtualizationProviderRoute -CimSession $Server).Count;
    }
    $HNVResults = $HNVResults + $ServerResults
}
$HNVResults | Select "Server", "Customer Routes", "Global Use External Router", "Lookup Records", "Provider Addresses", "Provider Routes" | Format-Table -AutoSize