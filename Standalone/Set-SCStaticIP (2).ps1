Function Set-SCStaticIP {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $SCVM, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $SCVirtualSwitch,
        [Parameter(Mandatory=$true,Position=3)]
        [String] $IPPoolName, `
        [Parameter(Mandatory=$true,Position=4)]
        [Object] $VMNetwork, `
        [Parameter(Mandatory=$true,Position=6)]
        [Int32] $NetworkAdapterNumber, `
        [Parameter(Mandatory=$false,Position=7)]
        [String] $IP) 
    
    Try {
    $VMNetwork = Get-SCVMNetwork -Name $VMNetwork
    #region Obtain VM Details
        Write-Host "Obtaining VM Details - " -NoNewline
            $VM = Get-SCVirtualMachine -Name $SCVM -ErrorAction Stop
            #$VMNetworkAdapter = Get-SCVirtualNetworkAdapter -Name "Test"
        Write-Host "Success" -ForegroundColor Green
    #endregion
    #region Obtain IP Pool Details
        Write-Host "Obtaining IP Pool Details - " -NoNewline
            $StaticIPPool = Get-SCStaticIPAddressPool -Name $IPPoolName -ErrorAction Stop
        Write-Host "Success" -NoNewline -ForegroundColor Green
        Write-Host " - " -NoNewline
        Write-Host $StaticIPPool.Name -ForegroundColor Cyan
    #endregion    
    #region Update VM Network Adapter
        Write-Host "Attempting to Update the VM NetworkAdapter - " -NoNewline
            #$empty = Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VM.VirtualNetworkAdapters[$NetworkAdapterNumber] -IPv4AddressType Static -VirtualNetwork $SCVirtualNetwork -ErrorAction Stop
            $empty = Set-SCVirtualNetworkAdapter `
                -VirtualNetworkAdapter $VM.VirtualNetworkAdapters[$NetworkAdapterNumber] `
                -VMNetwork $VMNetwork `
                -VirtualNetwork $SCVirtualSwitch #`
                #-IPv4AddressType Static -ErrorAction Stop
        Write-Host "Success" -ForegroundColor Green
    #endregion    
    #region Grant IP to VM
        Write-Host "Attempting to Grant IP to VM - " -NoNewline
            If ($IP -eq $null -or $IP -eq "") {
                $GrantedIP = Grant-SCIPAddress -GrantToObjectType VirtualNetworkAdapter -GrantToObjectID $VM.VirtualNetworkAdapters[$NetworkAdapterNumber].ID `
                    -StaticIPAddressPool $StaticIPPool -Description $VM.Name -ErrorAction Stop
            }
            Else {
                $GrantedIP = Grant-SCIPAddress -GrantToObjectType VirtualNetworkAdapter -GrantToObjectID $VM.VirtualNetworkAdapters[$NetworkAdapterNumber].ID `
                    -StaticIPAddressPool $StaticIPPool -Description $VM.Name -IPAddress $IP -ErrorAction Stop
            }
        Write-Host "Success" -NoNewline -ForegroundColor Green
        Write-Host " - " -NoNewline
        Write-Host $GrantedIP.Name -ForegroundColor Cyan
    #endregion    
    #region Set IP to VM
        Write-Host "Setting Granted IP to VM - " -NoNewline
            $empty = Set-SCIPAddress -AllocatedIPAddress $GrantedIP -GrantToObjectID $VM.VirtualNetworkAdapters[$NetworkAdapterNumber].ID -Description $VM.Name
        Write-Host "Success" -ForegroundColor Green
    #endregion
    #region Refresh VM
        Write-Host "Refreshing the VM - " -NoNewline
            $Empty = Get-SCVirtualMachine -Name $SCVM | Read-SCVirtualMachine
        Write-Host "Success" -ForegroundColor Green
    #endregion    
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        Break
    }
}
Clear-Host
#region Listing Functions
Function List-SCIPPools {
    Get-SCStaticIPAddressPool | Select Name
}

Function List-SCVMDetails {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $SCVM)

    Get-SCVirtualMachine -Name $SCVM | select -ExpandProperty VirtualNetworkAdapters | `
        Select `
            SlotID, `
            VirtualNetwork, `
            LogicalNetwork, `
            VMNetwork, `
            VMSubnet, `
            LogicalSwitch, `
            VLANID, `
            IPv4Addresses,`
            Name, `
            Enabled
}

Function List-SCVirtualMachines {
    Get-SCVirtualMachine | select Name
}

Function List-SCVirtualSwitches {
    Get-SCVirtualNetwork | select Name,LogicalNetworks
}

Function List-SCLogicalNetworks {
    Get-SCLogicalNetwork | select Name
}

Function List-SCVMNetworks {
    Get-SCVMNetwork | select name
}

Function Select-SCVMNetwork {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMNetwork)

    $VMNetwork = Get-SCVMNetwork -Name $VMNetwork
    Return $VMNetwork
}

Function List-SCIPAddress {
    Get-SCIPAddress | Select Name,Description
}

Function Remove-SCIP {
    Param (
        [Parameter(Mandatory=$True,Position=1)]
        [String] $IP)

    Try {
        Write-Host "Obtaining IP from SC IP Addresses - " -NoNewline
            $AllocatatedIP = Get-SCIPAddress -IPAddress $IP
        Write-Host "Success" -ForegroundColor Green
    
        Write-Host "Removing IP from SC IP Address" -NoNewline
            $Empty = Revoke-SCIPAddress -AllocatedIPAddress $AllocatatedIP
        Write-Host "Success" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
    }
}

#endregion
#$VMNetwork = Get-SCVMNetwork -Name "Back Network - Private"
#Set-SCStaticIP -SCVM "VIP-CLOUD-PDC" -SCVirtualSwitch RRAS -IPPoolName "Sage VM Network-84841c77ca2946d2a483bd1a563e5a85" -VMNetwork "Sage VM Network" -NetworkAdapterNumber 0 -IP "10.12.11.130"

Function SetVMNetworks {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [String] $VMName)   
$TenantVM = Get-SCVirtualMachine -Name "VIP-AFB"
$VirtualNetworkAdapter = Get-SCVirtualNetworkAdapter -VM $TenantVM #-Name "VIP-AFB" #-ID "42d94e32-0a48-4d37-b845-392c2d50ea14"
$VMNetwork = Get-SCVMNetwork -Name "Sage VM Network" #-ID "274e75bb-229e-4611-803c-6acf571f1adc"
$VMSubnet = Get-SCVMSubnet -Name "Sage VM Network-ca25cc8235da49d0a0c44f8da34636c9" #| where {$_.VMNetwork.ID -eq "274e75bb-229e-4611-803c-6acf571f1adc"}
Write-Host "Setting Virtual Network adapter - " -NoNewline
$Empty = Set-SCVirtualNetworkAdapter -VirtualNetworkAdapter $VirtualNetworkAdapter -VMNetwork $VMNetwork -VMSubnet $VMSubnet -VLanEnabled $false -VirtualNetwork "RRAS" -MACAddress "00:00:00:00:00:00" -MACAddressType Static -IPv4AddressType Dynamic -IPv6AddressType Dynamic -NoPortClassification 
Write-Host "Complete" -ForegroundColor Green
$VM = Get-SCVirtualMachine -Name "VIP-AFB" #-ID "d227f46d-a711-4b30-9416-a872f4d81c24" | where {$_.VMHost.Name -eq "NRAZUREVMH208.domain2.local"}
$OperatingSystem = Get-SCOperatingSystem  | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"} #-VMMServer vmm01.domain2.local -ID "56a7486f-b989-4bd3-b38a-a6c4bb206f1b" | where {$_.Name -eq "64-bit edition of Windows Server 2008 R2 Standard"}

#$CPUType = Get-SCCPUType -VMMServer vmm01.domain2.local | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}
Write-Host "Set Virtual Machine - " -NoNewline
$empty = Set-SCVirtualMachine -VM $VM -Name "VIP-AFB" -Description "" -OperatingSystem $OperatingSystem #-CPUCount 2 -MemoryMB 4096 -DynamicMemoryEnabled $true -DynamicMemoryMinimumMB 4096 -DynamicMemoryMaximumMB 4096 -DynamicMemoryBufferPercentage 20 -MemoryWeight 5000 -VirtualVideoAdapterEnabled $false -CPUExpectedUtilizationPercent 20 -DiskIops 0 -CPUMaximumPercent 100 -CPUReserve 0 -NumaIsolationRequired $false -NetworkUtilizationMbps 0 -CPURelativeWeight 100 -HighlyAvailable $true -HAVMPriority 2000 -DRProtectionRequired $false -NumLock $true -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" -CPULimitFunctionality $false -CPULimitForMigration $false -CPUType $CPUType -Tag "(none)" -QuotaPoint 1 -JobGroup 57a54697-f42b-40ba-a568-02fa64c9247e -RunAsynchronously -DelayStartSeconds 0 -BlockDynamicOptimization $false -EnableOperatingSystemShutdown $true -EnableTimeSynchronization $true -EnableDataExchange $true -EnableHeartbeat $true -EnableBackup $true -RunAsSystem -UseHardwareAssistedVirtualization $true 
Write-Host "Complete" -ForegroundColor Green
}

Set-SCStaticIP -SCVM "VIP-CURO" -SCVirtualSwitch RRAS -IPPoolName "Sage VM Network-84841c77ca2946d2a483bd1a563e5a85" -VMNetwork "Sage VM Network" -NetworkAdapterNumber 0 -IP "10.12.11.150"; SetVMNetworks -VMName "VIP-CURO"
#Set-SCStaticIP -SCVM "VIP-CLOUD-BDC" -SCVirtualSwitch RRAS -IPPoolName "Sage VM Network-84841c77ca2946d2a483bd1a563e5a85" -VMNetwork "Sage VM Network" -NetworkAdapterNumber 0 -IP "10.12.11.151"; SetVMNetworks -VMName "VIP-CLOUD-BDC"
