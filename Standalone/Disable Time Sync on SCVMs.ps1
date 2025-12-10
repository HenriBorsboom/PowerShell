Write-Host "Building VM List - " -NoNewline
    $VMs = Get-SCVirtualMachine
Write-Host "Complete" -ForegroundColor Green

$VMCount = $VMs.Count
Write-Host "Total VMs: $VMCount"
$VMCounter = 1

ForEach ($VM in $VMs.Name) {
    Try {
        Write-Host "$VMCounter\$VMCount - " -NoNewline
        Write-Host "$VM" -ForegroundColor Cyan -NoNewline
        Write-Host " - Disabling Time Sync - " -NoNewline
            $empty = Set-SCVirtualMachine -VM $VM -EnableTimeSync $false
        Write-Host "Complete" -ForegroundColor Green
        $VMCounter ++
    }
    Catch [Exception] {
        Write-Host "Failed" -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}


