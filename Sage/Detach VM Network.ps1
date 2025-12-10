# VM Network: "Sage VM Network"
# IP Pool - 10.20.12.0/24:   Sage VM Network-3bcb0dd95683467fa071df6ff45fe8da
# IP Pool - 10.12.11.128/25: Sage VM Network-84841c77ca2946d2a483bd1a563e5a85
# Logical Network: External - Public
# Switch: RRAS
#
#
#
#

Clear-Host
$VMS = Get-SCVirtualMachine | Where Name -like "VIP-*" | Sort Name

ForEach ($VM in $VMS) {
$VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VM $VM
Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -NoLogicalNetwork -NoConnection 
}

