Param(
    [Parameter(Mandatory=$true,Position=1)]
    [String] $ManIPLastOctet, `
    [Parameter(Mandatory=$true,Position=2)]
    [String] $CSVIPLastOctet, `
    [Parameter(Mandatory=$true,Position=3)]
    [String] $HBIPLastOctet)

Function Create-Networks {    
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $ManIPLastOctet, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $CSVIPLastOctet, `
        [Parameter(Mandatory=$true,Position=3)]
        [String] $HBIPLastOctet)

    $ManIP = "10.10.231." + $ManIPLastOctet
    $CSVIP = "10.10.145." + $CSVIPLastOctet
    $HtBIP = "10.10.29." + $HBIPLastOctet
    #Create new NIC team using two existing physical adapters in host, set LB and teaming mode
    New-NetLbfoTeam -Name NICTeam01 -TeamMembers pNIC1 -LoadBalancingAlgorithm TransportPorts -TeamingMode SwitchIndependent

    #Create new virtual switch using the NIC team created prior. Set to not allow hyper-v mgmt
    New-VMSwitch -Name ConvergedHyperSwitch -NetAdapterName NICTeam01 -AllowManagementOS $False -MinimumBandwidthMode Weight
                                                                                                                                                                                    
    #Create five virtual adapters for various components (LM,mgmt,cluster,iSCSI)
    Add-VMNetworkAdapter -ManagementOS -Name "Management" -SwitchName "ConvergedHyperSwitch"
    Add-VMNetworkAdapter -ManagementOS -Name "CSV" -SwitchName "ConvergedHyperSwitch"
    Add-VMNetworkAdapter -ManagementOS -Name "HB" -SwitchName "ConvergedHyperSwitch"

    #If required, set VLAN access for your virtual adapters
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Management" -Access -VlanId 2169
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "HB" -Access -VlanId 2170
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "CSV" -Access -VlanId 2167

    #Set minimum bandwidth in weighting (0-100)
    Set-VMNetworkAdapter -ManagementOS -Name "CSV" -MinimumBandwidthWeight 10
    Set-VMNetworkAdapter -ManagementOS -Name "Management" -MinimumBandwidthWeight 50
    Set-VMNetworkAdapter -ManagementOS -Name "HB" -MinimumBandwidthWeight 10

    #Set IP addresses/subnet on interfaces
    New-NetIPAddress -InterfaceAlias "vEthernet (Management)" -IPAddress $ManIP -PrefixLength "26" -DefaultGateway 10.10.231.193
    Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Management)" -ServerAddresses 10.10.16.142, 10.10.16.202
    New-NetIPAddress -InterfaceAlias "vEthernet (CSV)" -IPAddress $CSVIP -PrefixLength "26"
    New-NetIPAddress -InterfaceAlias "vEthernet (HB)" -IPAddress $HtBIP -PrefixLength "24"
}

Create-Networks -ManIPLastOctet $ManIPLastOctet -CSVIPLastOctet $CSVIPLastOctet -HBIPLastOctet $HBIPLastOctet


