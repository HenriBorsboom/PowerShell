<#
reg add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /t REG_DWORD /v ActiveHoursStart /d 9 /f   [Trigger: 8 AM Every Day]
reg add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /t REG_DWORD /v ActiveHoursEnd /d 3 /f   [Trigger: 8 AM Every Day]
reg add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /t REG_DWORD /v ActiveHoursStart /d 0 /f   [Trigger: 11 PM Every Day]
reg add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /t REG_DWORD /v ActiveHoursEnd /d 18 /f   [Trigger: 11 PM Every Day]
#>
Param (
    [Parameter(Mandatory=$True, Position=1)]
    [Int] $StartHour, `
    [Parameter(Mandatory=$True, Position=1)]
    [Int] $EndHour
)
Try {
    New-EventLog -LogName "Application" -source "ChangeActiveHours" | Out-Null
}
Catch {

}

Try {
    $LogFile = "D:\Apps\Captools\Scripts\ChangeActiveHours\Change_Active_Hours.txt"
    $Date = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    "Start Time" | Out-File $LogFile -Encoding ascii -Append
    $Date | Out-File $LogFile -Append -Encoding ascii
    Write-Host $Date

    "Current Active Hours Start" | Out-File $LogFile -Encoding ascii -Append
    $ActiveHoursStart = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursStart).ActiveHoursStart
    $ActiveHoursStart | Out-File $LogFile -Encoding ascii -Append
    Write-Host ("Current Active Hours Start " + $ActiveHoursStart.ToString())

    "Current Active Hours End"  | Out-File $LogFile -Encoding ascii -Append
    $ActiveHoursEnd = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursEnd).ActiveHoursEnd
    $ActiveHoursEnd | Out-File $LogFile -Encoding ascii -Append
    Write-Host ("Current Active Hours End " + $ActiveHoursEnd.ToString())

    ("Setting Active Hours to " + $StartHour.ToString()) | Out-File $LogFile -Encoding ascii -Append
    (Set-ItemProperty -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursStart -Value $StartHour)
    Write-Host ("Setting Active Hours to " + $StartHour.ToString())
    
    "New Active Hours Start"  | Out-File $LogFile -Encoding ascii -Append
    $NewActiveHoursStart = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursStart).ActiveHoursStart
    $NewActiveHoursStart | Out-File $LogFile -Encoding ascii -Append
    Write-Host ("New Active Hours Start " + $NewActiveHoursStart.ToString())
    
    ("Setting Active Hours End to " + $StartHour.ToString()) | Out-File $LogFile -Encoding ascii -Append
    (Set-ItemProperty -Path "HKLM:\Software\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursEnd -Value $EndHour)
    Write-Host ("Setting Active Hours End to " + $StartHour.ToString())
    
    "New Active Hours End" | Out-File $LogFile -Encoding ascii -Append
    $NewActiveHoursEnd = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name ActiveHoursEnd).ActiveHoursEnd
    $NewActiveHoursEnd | Out-File $LogFile -Encoding ascii -Append
    Write-Host ("New Active Hours End " + $NewActiveHoursEnd.ToString())
    
    "" | Out-File $LogFile -Encoding ascii -Append
    Write-Host ""
    Write-EventLog -LogName "Application" -Source "ChangeActiveHours" -EventId 1 -EntryType Information -Message ("Active Hours start changed to start hour: " + $StartHour.ToString() + " and Active Hours End hour to " + $EndHour.ToString()) -Category 1
}
Catch {
    Write-EventLog -LogName "Application" -Source "ChangeActiveHours" -EventId 2 -EntryType Error -Message ("Failed to change active Hours: Requested Start Hour: " +$StartHour.ToString() + " :End Hour: " + $EndHour.ToString() + " - Error: "  + $_) -Category 1
}