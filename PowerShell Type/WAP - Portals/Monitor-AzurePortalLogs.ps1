# Notes:
# Removed sentive information in strings and replaced with '<common descriptive info>'
# Replace the '' and the information inside with environment information

Function Remove-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}

Write-Host "Getting '<WAP Admin API>' Logs - "      -NoNewline; $1Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Admin API>'      -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Admin Portal>' Logs - "   -NoNewline; $2Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Admin Portal>'   -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Admin Auth>' Logs - "     -NoNewline; $3Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Admin Auth>'     -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Tenant API>' Logs - "     -NoNewline; $4Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Tenant API>'     -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Tenant Pub API>' Logs - " -NoNewline; $5Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Tenant Pub API>' -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Tenant Portal>' Logs - "  -NoNewline; $6Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Tenant Portal>'  -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Getting '<WAP Tenant Auth>' Logs - "    -NoNewline; $7Logs = Get-WinEvent -ListLog * -ComputerName '<WAP Tenant Auth>'    -Force -ErrorAction SilentlyContinue | Where-Object LogName -like 'Microsoft-WindowsAzurePack-*'
Write-Host "Complete"

For ($x = 1; $x -lt 1000000; $x ++) {
    Write-Host "'<WAP Admin API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Admin API>' -FilterHashtable @{logname=$1Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Admin Portal>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Admin API>' -FilterHashtable @{logname=$2Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Admin API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Admin API>' -FilterHashtable @{logname=$3Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Tenant API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Tenant API>' -FilterHashtable @{logname=$4Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Tenant API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Tenant API>' -FilterHashtable @{logname=$5Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Tenant API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Tenant API>' -FilterHashtable @{logname=$6Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    Write-Host "'<WAP Tenant API>' - $WAPLog" -ForegroundColor Cyan
    Get-WinEvent -ComputerName '<WAP Tenant API>' -FilterHashtable @{logname=$7Logs.LogName; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 5 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap

    For ($Delay = 1; $Delay -lt 60; $Delay ++) {
        Write-Host "|-- Waiting " -NoNewLine
        Write-Host $Delay -ForegroundColor Red -NoNewline
        Write-Host "/60 Seconds -- "
        Start-Sleep -Seconds 1
        Remove-LastLine
    }
}