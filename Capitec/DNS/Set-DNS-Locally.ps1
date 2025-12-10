Function Connect {
    param ($server)

    Enter-PSSession $Server -Credential $Credential
}
Clear-Host
get-netadapter
write-host "------------------" -ForegroundColor Cyan
$IfIndex = Read-Host "Interface Index: "
write-host "------------------" -ForegroundColor Cyan
Write-Host "Current DNS"
(Get-DnsClientServerAddress -InterfaceIndex $IfIndex -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses) -join ','
write-host "------------------" -ForegroundColor Cyan
Set-DnsClientServerAddress -InterfaceIndex $IfIndex -ServerAddresses @('10.100.100.100','10.101.101.101')
write-host "------------------" -ForegroundColor Cyan
Write-Host "New DNS"
(Get-DnsClientServerAddress -InterfaceIndex $IfIndex -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses) -join ','

