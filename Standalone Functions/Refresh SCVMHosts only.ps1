$SCVMHosts = Get-SCVMHost
$SCVMHosts = $SCVMHosts | Sort Name

$Count = $SCVMHosts.Count
$Counter = 1
Clear-Host
ForEach ($VMHOst in $SCVMHosts) {
    Write-Host $Counter "/" $Count " - " -NoNewline
    Write-Host $VMHOst.Name -NoNewline
    Write-Host " - " -NoNewline
    $Empty = Read-SCVMHost -VMHost $VMHOst
    Write-Host "Complete"
    $Counter ++
}