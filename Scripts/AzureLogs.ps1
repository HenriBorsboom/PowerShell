Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}

Write-Host "Getting NRAZUREAPP105 Logs - " -NoNewline
$APP105Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP105 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP106 Logs - " -NoNewline
$APP106Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP106 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP107 Logs - " -NoNewline
$APP107Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP107 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP108 Logs - " -NoNewline
$APP108Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP108 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP109 Logs - " -NoNewline
$APP109Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP109 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP110 Logs - " -NoNewline
$APP110Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP110 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"
Write-Host "Getting NRAZUREAPP111 Logs - " -NoNewline
$APP111Logs = Get-WinEvent -ListLog * -ComputerName NRAZUREAPP111 -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"

For ($x = 1; $x -lt 1000000; $x ++) {
    Write-Host "NRAZUREAPP105 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP105 -FilterHashtable @{logname=$APP105Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP106 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP106 -FilterHashtable @{logname=$APP106Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP107 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP107 -FilterHashtable @{logname=$APP107Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP108 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP108 -FilterHashtable @{logname=$APP108Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP109 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP109 -FilterHashtable @{logname=$APP109Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP110 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP110 -FilterHashtable @{logname=$APP110Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "NRAZUREAPP111 - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName NRAZUREAPP111 -FilterHashtable @{logname=$APP111Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    For ($Delay = 1; $Delay -lt 60; $Delay ++) {
        Write-Host "|-- Waiting " -NoNewLine
        Write-Host $Delay -ForegroundColor Red -NoNewline
        Write-Host "/60 Seconds -- "
        Sleep 1
        Delete-LastLine
    }
}