Clear-Host

$Hosts = @(
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

$Virt = @()
ForEach ($Server in $Hosts) {
    Write-Host $Server
    $PA = Get-NetVirtualizationProviderAddress -CimSession $Server
    $CR = Get-NetVirtualizationCustomerRoute -CimSession $Server
    If ($PA.Count -lt 0)     { $ProviderAddress = $false }
    ElseIf ($PA.Count -gt 0) { $ProviderAddress = $true }
    If ($CR.Count -lt 0)     { $CustomerRoute   = $false }
    ElseIf ($CR.Count -gt 0) { $CustomerRoute   = $true }
    $ServerDetails = New-Object PSObject -Property @{
        "Server"           = $Server
        "Provider Address" = $ProviderAddress
        "Customer Route"   = $CustomerRoute
    }
    $Virt = $Virt + $ServerDetails
}
$Virt