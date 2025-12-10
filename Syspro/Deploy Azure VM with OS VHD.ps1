$location = "Southeast Asia" 
$rgName = "prgsysrgprd01"
$subnetName = "PGAPPLICATIONNET"
$VNET = Get-AzureRmVirtualNetwork -Name "PGAsiaNet" -ResourceGroupName ‘PGResources’
$SubnetID = (Get-AzureRmVirtualNetworkSubnetConfig -Name ‘PGAPPLICATIONNET’ -VirtualNetwork $VNET).Id
$nicName = "prgprdrdssh01Nic"
$nic = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $rgname -Location $location -SubnetId $SubnetID
$vmName = "PRGPRDRDSSH01"
$osDiskName = $vmName + "osDisk"
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_D12_v2"
$vm = Add-AzureRmVMNetworkInterface -VM $vmConfig -Id $nic.Id
$osDiskUri = "https://prgsaprdapp02.blob.core.windows.net/vhds/PRGPRDRDSSH0120164175193.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $osDiskName -VhdUri $osDiskUri -CreateOption attach -Windows
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm 
