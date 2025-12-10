Param (
    [Parameter(Mandatory=$True,Position=1)]
    [String] $IP)

Try {
    Write-Host "Obtaining IP from SC IP Addresses - " -NoNewline
        $AllocatatedIP = Get-SCIPAddress -IPAddress $IP
    Write-Host "Success" -ForegroundColor Green
    
    Write-Host "Removing IP from SC IP Address - " -NoNewline
        $Empty = Revoke-SCIPAddress -AllocatedIPAddress $AllocatatedIP
    Write-Host "Success" -ForegroundColor Green
}
Catch {
    Write-Host "Failed" -ForegroundColor Red
}