# This only works on console scripts. Not in ISE
for ($i = 1; $i -lt 10; $i ++) {
    Write-Host $i.ToString()
    Start-Sleep -Seconds 1
    #Write-Host "Complete" -ForegroundColor Green
    if ($null -ne $psISE) {
        Write-Host "Script is running in PowerShell ISE."
    } 
    else {
        if ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($true)
            if ($key.Key -eq 'Escape') {
                Write-Host "Script execution stopped by user."
                break
            }
        }
    }
}