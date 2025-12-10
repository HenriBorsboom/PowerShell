(Get-WMIObject -Class Win32_OperatingSystem -Property Caption -ComputerName $Servers[$i]).Caption
(Test-Path ('\\' + $Servers[$i] + '\d$\Temp') -PathType Container)
Copy-Item 'D:\Temp\Henri\Change Active Hours.zip' -Destination ('\\' + $Servers[$i] + '\R$\Temp')
$ScriptBlock = {
    If (Test-Path D:\Apps\Captools\Scripts\ChangeActiveHours) {
        Remove-Item D:\Apps\Captools\Scripts\ChangeActiveHours -Recurse -Force
    }
    Expand-Archive -Path 'D:\Temp\Change Active Hours.zip' -DestinationPath D:\Apps\Captools\Scripts\ChangeActiveHours -Force
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
    If (Get-ScheduledTask | where taskname -like 'Change Active Hours*') {
        Write-Host "Removing Scheduled Tasks"
        Get-ScheduledTask | where taskname -like 'Change Active Hours*' | Unregister-ScheduledTask -Confirm:$False
                        
    }
    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 03-15.xml')) -TaskName 'Change Active Hours - 03-15'
    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 06-18.xml')) -TaskName 'Change Active Hours - 06-18'
    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 15-03.xml')) -TaskName 'Change Active Hours - 15-03'
    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 18-06.xml')) -TaskName 'Change Active Hours - 18-15'
    Start-ScheduledTask -TaskName 'Change Active Hours - 06-18'
    Start-Sleep -Seconds 2
    Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.ProviderName -eq 'ChangeActiveHours'} | Select Message
}
Invoke-Command -ComputerName $Servers[$i] -ScriptBlock $ScriptBlock










