$Location = "\\nrazurefls101\Windows Server 2012 R2 ISO Extract\sources\sxs"
Get-WindowsFeature -ComputerName NRAZUREVMH201 | Where InstallState -eq Installed | Install-WindowsFeature -Source $Location
