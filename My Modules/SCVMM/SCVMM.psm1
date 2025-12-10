Function Set-SCStaticIP {
<#
    .Synopsis
        Set a static IP address from an IP pool
    .Description
        The Set-SCStaticIP command sets a static IP fromthe IP Pool which is attached to a Virtual Switch
        and VM Network
    .Example
        Set-SCStaticIP `
                        -SCVM "MyVM" `
                        -SCVirtualSwitch "MyVirtualSwitch" `
                        -IPPoolName "My VMNetwork IP Pool" `
                        -VMNetwork "My VMNetwork" `
                        -VLANID 2 `
                        -NetworkAdapterNumber 0
                        -IP 10.0.0.10
        Sets a the static IP, "10.0.0.10" from the "My VMNetwork IP Pool", which is assigned 
        to "My VMNetwork", which is attached "MyVirtualSwitch", to the VM "MyVM" on network
        adapter 0
    .Example
        Set-SCStaticIP `
                        -SCVM "MyVM" `
                        -SCVirtualSwitch "MyVirtualSwitch" `
                        -IPPoolName "My VMNetwork IP Pool" `
                        -VMNetwork "My VMNetwork" `
                        -VLANID 2 `
                        -NetworkAdapterNumber 0
        Gets and sets a the static IP from the "My VMNetwork IP Pool", which is assigned 
        to "My VMNetwork", which is attached "MyVirtualSwitch", to the VM "MyVM" on network
        adapter 0            
    .Parameter SCVM
        The name of the Virtual Machine
    .Inputs
        [String]
    .Parameter SCVirtualSwitch
        The name of the Virtual Switch attached to the logical network
    .Inputs
        [String]
    .Parameter IPPoolName
        The name of the IP Pool to use that is assigned to the VM Network
    .Inputs
        [String]
    .Parameter VMNetwork
        The name of the VM Network to use that has the IP Pool specified
    .Inputs
        [String]
    .Parameter VLANID
        The VLANID to assign to the Virtual Machine
    .Inputs
        [Int32]
    .Parameter NetworkAdapterNumber
        The Virtual Machine's network adapter to assign the IP to
    .Inputs
        [Int32]
    .Parameter IP
        The IP to assign to the Virtual Machine's Network adapter
    .Inputs
        [String]
    .Notes
        NAME:  Set-SCStaticIP
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
    KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
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
        [String] $IP) #end param

    $VMNet = Get-SCVMNetwork -Name $VMNetwork

    Try {
    #region Obtain VM Details
        Write-Host "Obtaining VM Details - " -NoNewline
            $VM = Get-SCVirtualMachine -Name $SCVM -ErrorAction Stop
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
Function Show-SCIPPools {
<#
    .Synopsis
        Get the IP Address Pools
    .Description
        Get the Static IP Address Pools that are configured
    .Example
        Show-SCIPPools
        Displays the names of configured IP Pools
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCIPPools
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCStaticIPAddressPool | Select Name
}
Function Show-SCVMDetails {
<#
    .Synopsis
        Show network specific details of Virtual Machine
    .Description
        Gets the current Virtual Machine's network configuration.
        The information obtained here is tailored to only the Virtual Machine's Network
        adapter's Configuration.
    .Example
        Show-SCVMDetails -SCVM "MyVM"
        Displays the specified Virtual Machine's configured Slot ID, Virtual Network,
        Logical Network, VM Network, VM Subnet, Logical Switch, VLANID, IPv4 Addresses,
        Name and enabled status
    .Parameter SCVM
        The name of the virtual machine as shown in System Center 2012 R2 Virtual Machine Manager
    .Inputs
        [String]
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCVMDetails
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
    KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
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
Function Show-SCVirtualMachines {
<#
    .Synopsis
        Get the names of all the Virtual Machines in System Center 2012 R2 Virtual Machine Manager
    .Description
        Get a list of names of all the Virtual Machines managed by System Center 2012 R2
        Virtual Machine Manager
    .Example
        Show-SCVirtualMachines
        Display a list of all the Virtual Machines in System Center 2012 R2 Virtual Machine Manager
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCVirtualMachines
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCVirtualMachine | select Name
}
Function Show-SCVirtualSwitches {
<#
    .Synopsis
        Get the Virtual Switches and Logical Networks in System Center 2012 R2 Virtual Machine Manager
    .Description
        Get a list of Virtual Switches and the Logical Networks attached to them from System Center
        2012 R2 Virtual Machine Manager
    .Example
        Show-SCVirtualSwitches
        Display a table of all the Virtual Switches and Logical Networks attached to them from 
        System Center 2012 R2 Virtual Machine Manager
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCVirtualSwitches
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCVirtualNetwork | select Name,LogicalNetworks
}
Function Show-SCLogicalNetworks {
<#
    .Synopsis
        Display the names of all the Logical Networks configured
    .Description
        Display the names of all the Logical Networks configured
    .Example
        Show-SCLogicalNetworks
        Display the names of all the Logical Networks configured
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCLogicalNetworks
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCLogicalNetwork | select Name
}
Function Show-SCVMNetworks {
<#
    .Synopsis
        Display the VM Networks configured in System Center 2012 R2 Virtual Machine Manager
    .Description
        Display names of all the VM Networks configured in System Center 2012 R2 Virtual Machine
        Manager
    .Example
        Show-SCVMNetworks
        Displays the names of all the configured VM Networks in System Center 2012 R2 Virtual
        Machine Manager
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCVMNetworks
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCVMNetwork | select name
}
Function Select-SCVMNetwork {
<#
    .Synopsis
        Select a VM Network that is configured in System Center 2012 R2 Virtual Machine Manager
    .Description
        Returns a VM Network object from the VM Network name supplied that is configured in 
        System Center 2012 R2 Virtual Machine Manager
    .Example
        Select-SCVMNetwork -Name "MyVMNetwork"
        Returns the VMNetwork object from the supplied VM Network Name
    .Parameter Name
        The name of the VM Network
    .Inputs
        [String]
    .OutPuts
        [VMNetwork]
    .Notes
        NAME:  Select-SCVMNetwork
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMNetwork)

    $VMNetwork = Get-SCVMNetwork -Name $VMNetwork
    Return $VMNetwork
}
Function Show-SCIPAddress {
<#
    .Synopsis
        Get a table of configured IP Addresses and Virtual Machines
    .Description
        Display a table of the Virtual Machines and their attached Static IP Addresses which
        are configured by System Center 2012 R2 Virtual Machine Manager
    .Example
        Show-SCIPAddress
        Displays a table to Virtual Machines and their attached Static IP Addresses
    .OutPuts
        [String]
    .Notes
        NAME:  Show-SCIPAddress
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
    Get-SCIPAddress | Select Description,Name
}
Function Remove-SCIP {
<#
    .Synopsis
        Remove a static IP Address assigned to a Virtual Machine
    .Description
        Removes a static IP address that is assigned to a Virtual Machine
    .Example
        Remove-SCIP -IP "10.0.0.20"
        Removes the IP Address assigned to a Virtual Machine
    .Parameter IP
        The IP Address to be removed from a Virtual Machine
    .Inputs
        [String]
    .OutPuts
        [String]
    .Notes
        NAME:  Remove-SCIP
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>
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