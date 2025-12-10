#****Don't forget to go and get the Invoke-Parallel.ps1 script referenced in the associated blog post.*****

#Global Variables
# Where do we want to put the VM's
$global:locName = 'West Europe'
# Resource Group name
$global:rgName = 'PSTesting01'
# Virtual Network Name
$global:virtNetwork = 'PSTestingVnet01'
#  Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only
$global:stName = 'pstestingstorage01'
# VMName
$global:NewVM = $null
### New Variables
$global:SubscriptionName = 'Henri Boorsboom'

# MIM Servers to Auto Deploy
$VMRole = @()
$VMRole += ,('MIMPortal1')
$VMRole += ,('MIMPortal2')
$VMRole += ,('MIMSync')
$VMRole += ,('ADDC1')
$VMRole += ,('ADDC2')

# Authenticate to the Azure Portal
Add-AzureRmAccount -Credential (Get-Credential)

# Get the UserID and Password info that we want associated with the new VM's.
$global:cred = Get-Credential -Message "Type the name and password for the local administrator account that will be created for your new VM(s)."

#$SubscriptionName = Get-AzureRmSubscription | sort SubscriptionName | Select SubscriptionName
#$SubscriptionName = $SubscriptionName.SubscriptionName
Select-AzureRmSubscription -SubscriptionName $SubscriptionName 

# Create Resource Group
New-AzureRmResourceGroup -Name $rgName -Location $locName
# Create RG Storage Account
$storageAcc = New-AzureRmStorageAccount -ResourceGroupName $rgName -Name $stName -Type "Standard_LRS" -Location $locName
# Create RG Subnet
$singleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name singleSubnet -AddressPrefix 10.0.0.0/24
# Create RG Network
$global:vnet = New-AzureRmVirtualNetwork -Name $virtNetwork -ResourceGroupName $rgName -Location $locName -AddressPrefix 10.0.0.0/16 -Subnet $singleSubnet

# VM Config for each VM
$VMConfig = @()
# Create VMConfigs and add to an array
#foreach ($NewVM in $VMRole) {
    # ******** Create IP and Network for the VM ***************************************
    # *****We do this upfront before the bulk create of the VM**************
    #$pip = New-AzureRmPublicIpAddress -Name "$NewVM-IP1" -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
    $pip = New-AzureRmPublicIpAddress -Name ($VMRole[0] + "-IP1") -ResourceGroupName $rgName -Location $locName -AllocationMethod Dynamic
    #$nic = New-AzureRmNetworkInterface -Name "$NewVM-NIC1" -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id
    $nic = New-AzureRmNetworkInterface -Name ($VMRole[0] + "-NIC1") -ResourceGroupName $rgName -Location $locName -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id

    #$vm = New-AzureRmVMConfig -VMName $NewVM -VMSize "Standard_A1"
    $vm = New-AzureRmVMConfig -VMName $VMRole[0] -VMSize "Standard_A1"
    #$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $NewVM -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
    $vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $VMRole[0] -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

    $vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2012-R2-Datacenter -Version "latest"
    $vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id
    # VM Disks. Deploying an OS and a Data Disk for each
    #$osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/WindowsVMosDisk$NewVM.vhd" 
    $osDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMosDisk" + $VMRole[0] + ".vhd")
    #$DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + "vhds/WindowsVMDataDisk$NewVM.vhd"
    $DataDiskUri = $storageAcc.PrimaryEndpoints.Blob.ToString() + ("vhds/WindowsVMDataDisk" + $VMRole[0] + ".vhd")
    $vm = Set-AzureRmVMOSDisk -VM $vm -Name "windowsvmosdisk" -VhdUri $osDiskUri -CreateOption fromImage
    $vm = Add-AzureRmVMDataDisk -VM $vm -Name "windowsvmdatadisk" -VhdUri $DataDiskUri -CreateOption Empty -Caching 'None' -DiskSizeInGB 10 -Lun 0
    # Add the Config to an Array
    $VMConfig += ,($vm)
    # ******** End NEW VM ***************************************
#}

  
# In Parallel Create all the VM's
$VMConfig | Invoke-Parallel -ImportVariables -ScriptBlock  {
    New-AzureRmVM -ResourceGroupName $rgName -Location $locName -VM $_
}


