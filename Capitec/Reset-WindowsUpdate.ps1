net stop wuauserv
net stop cryptSvc
net stop bits
net stop msiserver
Ren C:\Windows\SoftwareDistribution SoftwareDistribution.old
Ren C:\Windows\System32\catroot2 Catroot2.old
net start wuauserv
net start cryptSvc
net start bits
net start msiserver

Stop-Service wuauserv
Stop-Service cryptSvc
Stop-Service bits
Stop-Service msiserver
Rename-Item C:\Windows\SoftwareDistribution SoftwareDistribution.old -Force
Rename-Item C:\Windows\System32\catroot2 Catroot2.old -Force
Start-Service wuauserv
Start-Service cryptSvc
Start-Service bits
Start-Service msiserver
