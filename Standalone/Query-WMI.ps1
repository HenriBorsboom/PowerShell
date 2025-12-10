Clear-Host
$ErrorActionPreference = "SilentlyContinue"
$Servers = @(
"LEATITIASVR"
"SYSJHBHV1"
"SYSJHBHV3"
"SYSJHBPROXY"
"SYSPRO-DEVELOP"
"SYSPRO-ERRTRK"
"SYSPRO-SAS3K"
"SYSPRO-SASSERV"
"SYSPRO-STRIPSER"
"THABOT"
"VUSIWIN12"
)
ForEach ($Server in $Servers) {
    Write-Host "Getting installed products on $Server - " -NoNewline
    $Results = (Get-WmiObject -Query "Select Name from Win32_Product" -ComputerName $Server).Name
    $Results | Out-File C:\Temp\$Server.txt -Encoding ascii -Force -NoClobber
    Write-Host "Complete"
}