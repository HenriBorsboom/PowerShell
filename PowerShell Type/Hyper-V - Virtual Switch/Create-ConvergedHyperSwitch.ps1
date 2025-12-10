Param(
    [Parameter(Mandatory = $True, Position =  1)]
    [String]    $TeamName, `
    [Parameter(Mandatory = $True, Position =  2)]
    [String]    $NIC1Name, `
    [Parameter(Mandatory = $True, Position =  3)]
    [String]    $NIC2Name, `
    [Parameter(Mandatory = $True, Position =  4)]
    [String]    $VirtualSwitchName, `
    [Parameter(Mandatory = $True, Position =  5)]
    [Int16]     $ManagementVLAN, `
    [Parameter(Mandatory = $True, Position =  6)]
    [IPAddress] $ManagementIP, `
    [Parameter(Mandatory = $True, Position =  7)]
    [Int16]     $ManagementPrefix, `
    [Parameter(Mandatory = $True, Position =  8)]
    [IPAddress] $ManagementGateway, `
    [Parameter(Mandatory = $True, Position =  9)]
    [String[]]  $ManagementDNSServers, `
    [Parameter(Mandatory = $True, Position = 10)]
    [Int16]     $HeartbeatVLAN, `
    [Parameter(Mandatory = $True, Position = 11)]
    [IPAddress] $HearbeatIP, `
    [Parameter(Mandatory = $True, Position = 12)]
    [Int16]     $HeartbeatPrefix, `
    [Parameter(Mandatory = $True, Position = 13)]
    [Int16]     $ClusteredSharedVolumeVLAN, `
    [Parameter(Mandatory = $True, Position = 14)]
    [IPAddress] $ClusterSharedVolumeIP, `
    [Parameter(Mandatory = $True, Position = 15)]
    [Int16]     $ClusterSharedVolumePrefix)
Function Create-Networks {    
    Param(
        [Parameter(Mandatory = $True, Position =  1)]
        [String]    $TeamName, `
        [Parameter(Mandatory = $True, Position =  2)]
        [String]    $NIC1Name, `
        [Parameter(Mandatory = $True, Position =  3)]
        [String]    $NIC2Name, `
        [Parameter(Mandatory = $True, Position =  4)]
        [String]    $VirtualSwitchName, `
        [Parameter(Mandatory = $True, Position =  5)]
        [Int16]     $ManagementVLAN, `
        [Parameter(Mandatory = $True, Position =  6)]
        [IPAddress] $ManagementIP, `
        [Parameter(Mandatory = $True, Position =  7)]
        [Int16]     $ManagementPrefix, `
        [Parameter(Mandatory = $True, Position =  8)]
        [IPAddress] $ManagementGateway, `
        [Parameter(Mandatory = $True, Position =  9)]
        [String[]]  $ManagementDNSServers, `
        [Parameter(Mandatory = $True, Position = 10)]
        [Int16]     $HeartbeatVLAN, `
        [Parameter(Mandatory = $True, Position = 11)]
        [IPAddress] $HearbeatIP, `
        [Parameter(Mandatory = $True, Position = 12)]
        [Int16]     $HeartbeatPrefix, `
        [Parameter(Mandatory = $True, Position = 13)]
        [Int16]     $ClusteredSharedVolumeVLAN, `
        [Parameter(Mandatory = $True, Position = 14)]
        [IPAddress] $ClusterSharedVolumeIP, `
        [Parameter(Mandatory = $True, Position = 15)]
        [Int16]     $ClusterSharedVolumePrefix)

    #region Create new NIC team using two existing physical adapters in host, set LB and teaming mode
    New-NetLbfoTeam -Name $TeamName -TeamMembers $NIC1Name,$NIC2Name -LoadBalancingAlgorithm TransportPorts -TeamingMode SwitchIndependent
    #endregion
    #region Create new virtual switch using the NIC team created prior. Set to not allow hyper-v mgmt
    New-VMSwitch -Name $VirtualSwitchName -NetAdapterName $TeamName -AllowManagementOS $False -MinimumBandwidthMode Weight
    #endregion
    #region Create three virtual adapters for various components (Management, Heartbeat, Clustered Shared Volumes)
    Add-VMNetworkAdapter -ManagementOS -Name "Management ($ManagementVLAN)"                         -SwitchName $TeamName
    Add-VMNetworkAdapter -ManagementOS -Name "Heartbeat ($HeartbeatVLAN)"                           -SwitchName $TeamName
    Add-VMNetworkAdapter -ManagementOS -Name "Clustered Shared Volume ($ClusteredSharedVolumeVLAN)" -SwitchName $TeamName
    #endregion
    #region If required, set VLAN access for your virtual adapters
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Management ($ManagementVLAN)"                         -Access -VlanId $ManagementVLAN
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Heartbeat ($HeartbeatVLAN)"                           -Access -VlanId $HeartbeatVLAN
    Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Clustered Shared Volume ($ClusteredSharedVolumeVLAN)" -Access -VlanId $ClusteredSharedVolumeVLAN
    #endregion
    #region Set minimum bandwidth in weighting (0-100)
    Set-VMNetworkAdapter -ManagementOS -Name "Management ($ManagementVLAN)"                         -MinimumBandwidthWeight 50
    Set-VMNetworkAdapter -ManagementOS -Name "Heartbeat ($HeartbeatVLAN)"                           -MinimumBandwidthWeight 10
    Set-VMNetworkAdapter -ManagementOS -Name "Clustered Shared Volume ($ClusteredSharedVolumeVLAN)" -MinimumBandwidthWeight 10
    #endregion
    #region Set IP addresses/subnet on interfaces
    New-NetIPAddress -InterfaceAlias "vEthernet (Management ($ManagementVLAN))"                         -IPAddress $ManagementIP          -PrefixLength $ManagementPrefix -DefaultGateway $ManagementGateway
    New-NetIPAddress -InterfaceAlias "vEthernet (Heartbeat ($HeartbeatVLAN))"                           -IPAddress $HearbeatIP            -PrefixLength $HeartbeatPrefix
    New-NetIPAddress -InterfaceAlias "vEthernet (Clustered Shared Volume ($ClusteredSharedVolumeVLAN))" -IPAddress $ClusterSharedVolumeIP -PrefixLength $ClusterSharedVolumePrefix
    #endregion
    #region Set DNS addresses on Management Interface
    Set-DnsClientServerAddress -InterfaceAlias "vEthernet (Management ($ManagementVLAN))" -ServerAddresses $ManagementDNSServers
    #endregion
}

Create-Networks `
    -TeamName                  $TeamName `
    -NIC1Name                  $NIC1Name `
    -NIC2Name                  $NIC2Name `
    -VirtualSwitchName         $VirtualSwitchName `
    -ManagementVLAN            $ManagementVLAN `
    -ManagementIP              $ManagementIP `
    -ManagementPrefix          $ManagementPrefix `
    -ManagementGateway         $ManagementGateway `
    -ManagementDNSServers      $ManagementDNSServers `
    -HeartbeatVLAN             $HeartbeatVLAN `
    -HearbeatIP                $HeartbeatVLAN `
    -HeartbeatPrefix           $HeartbeatPrefix `
    -ClusteredSharedVolumeVLAN $ClusteredSharedVolumeVLAN `
    -ClusterSharedVolumeIP     $ClusterSharedVolumeIP `
    -ClusterSharedVolumePrefix $ClusterSharedVolumePrefix