Function Send-Notification {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Message
    )
    # Pushbullet API Token
    $apiKey = "o.UB6yGbEcWBblTcsRPmOSCHgHpxMeq9fu"

    # Notification Message
    #$message = "Your PowerShell script has completed."

    # Send Notification
    Invoke-RestMethod -Uri "https://api.pushbullet.com/v2/pushes" `
                    -Method Post `
                    -Headers @{ "Access-Token" = $apiKey } `
                    -Body @{ "type" = "note"; "title" = "PowerShell Script"; "body" = $message }
}
Function ControlStop {
    if ($null -ne $psISE) {
        #Write-Host "Script is running in PowerShell ISE."
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
$Run = $true
$StartTime = Get-Date
$MonitorFile = '\\CBFP01\Temp\ScriptComplete.txt'
Write-Host ("Starting monitor: " + $StartTime -f '{0:yyyy/MM/dd H:mm:ss}')
While ($Run -eq $True) {
    #Write-Host $i.ToString()
    #$EndTime = Get-Date
    If (Test-Path $MonitorFile) {
        #$Run = $false
        #($StartTime) | Out-File $MonitorFile -Encoding ascii -Append
        #($EndTime) | Out-File $MonitorFile -Encoding ascii -Append
        #("Running Time: " + ($EndTime - $StartTime) -f "{0:HH:mm:ss}") | Out-File $MonitorFile -Encoding ascii -Append
        Send-Notification -Message ((Get-Content $MonitorFile) -join " - ")
        Remove-Item $MonitorFile
        #$StartTime = Get-Date
    }
    ControlStop
    Start-Sleep -Seconds 1
}
Write-Host (($EndTime - $StartTime) -f "{0:HH:mm:ss}")