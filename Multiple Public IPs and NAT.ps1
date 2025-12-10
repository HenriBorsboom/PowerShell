Get-NetNatGlobal
Get-NetNatExternalAddress | where {$_.IPAddress -eq "165.233.158.32"}
$NATName = "d71d0886-6233-4e47-96e1-b26def79e2bf"
Get-NetNat -Name $NATName
Get-NetNatExternalAddress | Select IPAddress
Add-NetNatExternalAddress -NatName $NATName -IPAddress 165.233.158.149 -PortStart 1 -PortEnd 47999
Get-NetNatExternalAddress -NatName $NATName
Add-NetNatStaticMapping -NatName $NATName -Protocol TCP -ExternalIPAddress 165.233.158.33 -ExternalPort 25 -InternalIPAddress 10.12.11.95 -InternalPort 25
Get-SCStaticIPAddressPool -Name "RRAS VM Network 1-036a0172207a4cc18222c56c1db6bb96" | Get-SCIPAddress | select Address