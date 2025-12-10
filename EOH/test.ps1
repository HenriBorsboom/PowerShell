If ($Host.Name -notlike '*ISE*') {
    clear-host
    [console]::SetCursorPosition(0, 1)
    write-host "Line 1"
    [console]::SetCursorPosition(0, 0)
    write-host "Line 2"
    [console]::SetCursorPosition(0, 2)
}
Else {
    Start-Process powershell 'C:\Users\henri.borsboom\Documents\Scripts\PowerShell\EOH\test.ps1'
}


Read-Host "Done"