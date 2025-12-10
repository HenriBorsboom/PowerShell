$SCVMHosts = Get-SCVMHost

$x = 1
ForEach ($SCVMHost in $SCVMHosts) {
    Try {
        Write-Host "$x - Processing " $SCVMHost.Name -NoNewline
        Write-Host '... ' -NoNewline
        $empty = Read-SCVMHost -VMHost $SCVMHost
        Write-Host 'Complete' -ForegroundColor Green
    }
    Catch {
        Write-Host 'Failed' -ForegroundColor Red
    }
    $x ++
}