$NATName = Get-NetNatExternalAddress | where {$_.IPAddress -eq "198.51.100.10"}
$NATName = $NATName.Natname.ToString()
Add-NetNatExternalAddress -NatName $NATName -IPAddress 198.51.100.11 -PortStart 1 -PortEnd 47999
For ($NATPort = 1; $NATPort -lt 47999; $NATPort ++) {
Add-NetNatStaticMapping -NatName $NATName -Protocol TCP -ExternalIPAddress 198.51.100.11 -ExternalPort $NATPort -InternalIPAddress 10.1.16.12 -InternalPort $NATPort
}
