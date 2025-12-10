$VMHosts = @(
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

Try {
    ForEach ($VMHost in $VMHosts) {
        Write-Host "Collecting SCVMHost information - " -NoNewline
        Write-Host "$VMHost - " -ForegroundColor Cyan -NoNewline    
            $VMHost = Get-SCVMHost -ComputerName $VMHost
        Write-Host "Complete" -ForegroundColor Green

        Write-Host "Collecting SCVMHost Network Adapater information - " -NoNewline
        Write-Host "$VMHost - " -ForegroundColor Cyan -NoNewline    
            $vmHostNetworkAdapter = Get-SCVMHostNetworkAdapter -VMHost $VMHost | Where ConnectionName -eq "NICTeam01"
            $empty = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $vmHostNetworkAdapter -Description "" -AvailableForPlacement $true -UsedForManagement $true #-JobGroup "4840a462-3809-4e33-aa29-2fe4fd9fbe8a"
        Write-Host "Complete" -ForegroundColor Green

        Write-Host "Adding - " -NoNewline
        Write-Host "Back Network - Management - " -ForegroundColor Cyan -NoNewline    
            $logicalNetwork = Get-SCLogicalNetwork -Name "Back Network - Management" #-ID "928b2dcc-b9e8-4fd7-8e14-058dafd36290"
            $empty = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $vmHostNetworkAdapter -RemoveLogicalNetwork $logicalNetwork #-JobGroup "4840a462-3809-4e33-aa29-2fe4fd9fbe8a" 
        Write-Host "Complete" -ForegroundColor Green

        Write-Host "Adding - " -NoNewline
        Write-Host "External Network - Public - " -ForegroundColor Cyan -NoNewline    
            $logicalNetwork = Get-SCLogicalNetwork -Name "External Network - Public" #-ID "c47e3eff-f61e-4a60-b74c-0efd6bde2fa4"
            $empty = Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $vmHostNetworkAdapter -RemoveLogicalNetwork $logicalNetwork #-JobGroup "4840a462-3809-4e33-aa29-2fe4fd9fbe8a" 
        Write-Host "Complete" -ForegroundColor Green
    
    }
}
Catch [Exception] {
    Write-Host $_.Exception.Message
    return
    Break
}


