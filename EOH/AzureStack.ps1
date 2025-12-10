net stop w32time
w32tm /unregister
w32tm /register
net start w32time
w32tm /config /manualpeerlist:196.21.187.2 /syncfromflags:MANUAL /reliable:YES /update
w32tm /resync /rediscover
w32tm /query /status


.\InstallAzureStackPOC.ps1 -UseADFS -AdminPassword (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force) -DNSForwarder 192.168.0.1 -TimeServer 196.21.187.2
.\InstallAzureStackPOC.ps1 -UseADFS -AdminPassword (ConvertTo-SecureString -String 'P@ssw0rd' -AsPlainText -Force) -TimeServer 196.21.187.2