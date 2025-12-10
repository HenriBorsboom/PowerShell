$SCVMHosts = Get-SCVMHost

$SCVMHosts = @(
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

$x = 1
ForEach ($SCVMHost in $SCVMHosts) {
    Try {
        $SCVMHostName = Get-SCVMHost $SCVMHost
        Write-Host "$x - Processing " $SCVMHostName -NoNewline
        Write-Host '... ' -NoNewline
        $empty = Read-SCVMHost -VMHost $SCVMHostName
        Write-Host 'Complete' -ForegroundColor Green
    }
    Catch {
        Write-Host 'Failed' -ForegroundColor Red
    }
    $x ++
}