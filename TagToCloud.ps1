$VMs = Get-SCVirtualMachine | where Name -like "VIP-*"

ForEach ($VM in $VMS) {
#$VM = Get-SCVirtualMachine -Name "VIP-AXIOMATIC"
    Try {
    $Cloud = Get-SCCloud -VMMServer vmm01.domain2.local | where {$_.Name -eq "Business Connexion Azure Pack"}
    Write-Host "Setting " -NoNewline
    Write-Host $VM.Name -NoNewline -ForegroundColor Yellow
    Write-Host " - " -NoNewline
        $Empty = Set-SCVirtualMachine -VM $VM -Name "VIP-AXIOMATIC" -Description "" -Cloud $Cloud -ErrorAction Stop
    Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
    Write-Host "Failed" -ForegroundColor Red
    Write-Output $_
    Write-Host ""
    }
}
