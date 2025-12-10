#    Param (
#        [Parameter(Mandatory=$true,Position=1)]
#        [String] $SCVM, `
#        [Parameter(Mandatory=$true,Position=2)]
#        [String] $SCVirtualSwitch,
#        [Parameter(Mandatory=$true,Position=3)]
#        [String] $IPPoolName, `
#        [Parameter(Mandatory=$true,Position=4)]
#        [Object] $VMNetwork, `
#        [Parameter(Mandatory=$true,Position=5)]
#        [String] $VLANID, `
#        [Parameter(Mandatory=$true,Position=6)]
#        [Int32] $NetworkAdapterNumber, `
#        [Parameter(Mandatory=$false,Position=7)]
#        [String] $IP) 

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
        [Parameter(Mandatory=$true,Position=5)]
        [String] $VLANID, `
        [Parameter(Mandatory=$true,Position=6)]
        [Int32] $NetworkAdapterNumber, `
        [Parameter(Mandatory=$false,Position=7)]
        [String] $IP) 

    $VMNet = Get-SCVMNetwork -Name $VMNetwork
    
    Try {
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
            $empty = Set-SCVirtualNetworkAdapter `
                -VirtualNetworkAdapter $VM.VirtualNetworkAdapters[$NetworkAdapterNumber] `
                -VMNetwork $VMNet `
                -VLanEnabled $true `
                -VLanID $VLANID `
                -VirtualNetwork $SCVirtualSwitch `
                -IPv4AddressType Static -ErrorAction Stop
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
        Break
    }
}

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
    }
}

#endregion
#$VMNetwork = Get-SCVMNetwork -Name "Back Network - Private"
#Set-SCStaticIP -SCVM "Test" -SCVirtualSwitch "ConvergedHyperSwitch" -IPPoolName "Management" -VMNetwork $VMNetwork -VLANID 2166 -NetworkAdapterNumber 0
#Set-SCStaticIP -SCVM $SCVM -SCVirtualSwitch $SCVirtualSwitch -IPPoolName $IPPoolName -VMNetwork $VMNetwork -VLANID VLANID -NetworkAdapterNumber $NetworkAdapterNumber -IP $IP


Set-SCStaticIP -SCVM "VMSERVER201" -SCVirtualSwitch "ConvergedHyperSwitch" -IPPoolName "Windows Azure Pack Services" -VMNetwork "Front Network - Private" -VLANID 2168 -NetworkAdapterNumber 0 -IP 10.0.145.86
#Set-SCStaticIP -SCVM "WEBSERVER108" -SCVirtualSwitch "ConvergedHyperSwitch" -IPPoolName "Windows Azure Pack Services" -VMNetwork "Front Network - Private" -VLANID 2168 -NetworkAdapterNumber 0
