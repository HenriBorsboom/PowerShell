For ($x = 0; $x -lt 100000; $x ++) {
    Clear-Host; Get-SCOMAlert | Where-Object {$_.ResolutionState -eq 0} | Where-Object {$_.Severity -eq "Error"}
    Write-Host
    Write-Host "$x - Sleeping 10 seconds"
    sleep 10
}