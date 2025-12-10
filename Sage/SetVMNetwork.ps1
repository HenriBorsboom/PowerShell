Function SetVMNetworks {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [String] $VMName)   
$TenantVM = Get-SCVirtualMachine -Name "VIP-AFB"
$VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VM $TenantVM #-Name "VIP-AFB" #-ID "42d94e32-0a48-4d37-b845-392c2d50ea14"
$VMNetwork = Get-SCVMNetwork -Name "Sage VM Network" #-ID "274e75bb-229e-4611-803c-6acf571f1adc"
$VMSubnet = Get-SCVMSubnet -Name "Sage VM Network-ca25cc8235da49d0a0c44f8da34636c9" #| where {$_.VMNetwork.ID -eq "274e75bb-229e-4611-803c-6acf571f1adc"}
Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -VMNetwork $VMNetwork -VMSubnet $VMSubnet -VLanEnabled $false -VirtualNetwork "RRAS" -MACAddress "00:00:00:00:00:00" -MACAddressType Static -IPv4AddressType Dynamic -IPv6AddressType Dynamic -NoPortClassification 

$VM = Get-SCVirtualMachine -Name "VIP-AFB" #-ID "d227f46d-a711-4b30-9416-a872f4d81c24" | where {$_.VMHost.Name -eq "NRAZUREVMH208.domain2.local"}
$OperatingSystem = Get-SCOperatingSystem  | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"} #-VMMServer vmm01.domain2.local -ID "56a7486f-b989-4bd3-b38a-a6c4bb206f1b" | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"}

#$CPUType = Get-SCCPUType -VMMServer vmm01.domain2.local | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}

Set-SCVirtualMachine -VM $VM -Name "VIP-AFB" -Description "" -OperatingSystem $OperatingSystem #-CPUCount 2 -MemoryMB 4096 -DynamicMemoryEnabled $true -DynamicMemoryMinimumMB 4096 -DynamicMemoryMaximumMB 4096 -DynamicMemoryBufferPercentage 20 -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $true -HAVMPriority 2000 -DRProtectionRequired $false -NumLock $true -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -CPULimitFunctionality $false -CPULimitForMigration $false -CPUType $CPUType -Tag "(none)" -QuotaPoint 1 -JobGroup 57a54697-f42b-40ba-a568-02fa64c9247e -RunAsynchronously -DelayStartSeconds 0 -BlockDynamicOptimization $false -EnableOperatingSystemShutdown $true -EnableTimeSynchronization $true -EnableDataExchange $true -EnableHeartbeat $true -EnableBackup $true -RunAsSystem -UseHardwareAssistedVirtualization $true 
}