$VMS = Get-SCVirtualMachine | Where Name -like "VIP-*" | Sort Name

ForEach ($VM in $VMS) {
$VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VM $VM
Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -NoLogicalNetwork -NoConnection 
}

