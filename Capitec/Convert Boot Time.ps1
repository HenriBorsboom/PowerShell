$WMI = Get-WmiObject -Class Win32_OperatingSystem -Property LastBootUpTime
$Result = $WMI.ConvertToDateTime($WMI.LastBootUpTime) 
$UpTime = $Result -f '{0:yyyy/MM/dd HH:mm:ss}'
$Uptime

