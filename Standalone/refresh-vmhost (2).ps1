Write-Host "Getting the Hosts " -NoNewline
$VMHosts = Get-SCVMHost
Write-Host "Complete" -ForegroundColor Green

ForEach ($VMHost in $VMHosts)
{
    $HostName = $VMHost.Name
    Write-Host " Reading Host - $VMhost - information " -NoNewline
    $Empty = Read-SCVMHost -VMHost $VMHost
    Write-Host "Complete" -ForegroundColor Green
}

