#get-vmswitch -computername "cl5007a-th" | Get-VMSwitchExtension | where {$_.name -match "Microsoft VMM DHCP*"} | fl computername, switchname, name, enabled, running
get-netvirtualizationcustomerroute -cimsession "Server"
Get-NetVirtualizationLookupRecord | where {$_.VMName -match "vmname"} | Fl CustomerAddress, VirtualsubnetID, MacAddress, ProviderAddress

Get-NetworkVirtualizationProviderAddress | Where {$_.ProviderAddress – eq "172.172.10.4"
Get-NetAdapter | Where {$_.ifIndex –eq "11"}
Get-NetAdapterStatistics
#Check logical switch compliance
Get-SCVirtualnetwork -name "PrivateLs" | fl logicalnetworks, logicalswitch, vmhostnetworkadapters, logicalswitchcompliance*
#Confirm ability to communicate from PA to all hosts that support a given logical network
Get-NetVirtualizationProviderAddress –cimsession "cl5007a-th" | where {S_.ProviderAddress –eq "172.172.10.4"}
ping –p 172.172.10.4
Get-NetVirtualizationProviderAddress –cimsession "cl5007e-th" | where {S_.ProviderAddress –eq "172.172.10.2"}
ping –p 172.172.10.2

#Step 3: Check guest network settings and configuration
#Review guest network connection
Get-VM | where {$_.name -match "WS_10074*"} | Get-VMNetworkAdapter | sort-object MacAddress | fl VMName, MacAddress, SwitchName, Status, IPAddresses
Get-SCVirtualMachine | where {$_.name -match "WS_10074*"} | Get-SCVirtualNetworkAdapter | sort-object | fl MacAddress, VirtualNetwork, LogicalNetwork, IPv4Addresses, IPv4Subnets
Get-SCStaticIPAddressPool | where {$_.VMSubnet -match "test"} | fl VMSubnet, Name, IPAddressRangeStart, IPAddressRangeEnd, DefaultGateways
Get-SCIPAddress | where {$_.name –eq "192.168.0.2"} | fl Address, AllocatingAddressPool, State, Description
#Check VM access to the network gateway

#Step 4: Check Hyper-V Network Virtualization gateway settings
#Confirm that the right gateway is being used
get-scvmnetwork -name "test" | fl name, LogicalNetwork, VMSubnet, VMNetworkGateways, VPNConnections, NATConnections, RoutingDomainID, IsolationType, HasGatewayConnection
get-service -computername "txtstgwclu01" remoteaccess
get-scvmnetwork -name "test" | fl name, LogicalNetwork, VMSubnet, VMNetworkGateways, VPNConnections, NATConnections, RoutingDomainID, IsolationType, HasGatewayConnection
get-netcompartment -cimsession "txtstgwclu01" | where {$_.CompartmentGuid -match "ec0db49f-6fc1-4a75-9905-e08c8dfa0a25"} | fl *
#Verify configuration for each type of gateway in use
#Site-to-site gateway
get-remoteaccessroutingdomain -cimsession "txtstgwclu01" -name "Testec0db49f-6fc1-4a75-9905-e08c8dfa0a25"
get-VpnS2SInterface -cimsession "txtstgwclu01" -name "Testec0db49f-6fc1-4a75-9905-e08c8dfa0a25" | fl *
#dynamic routing through BGP
Get-BGPRouter -cimsession "txtstgwclu01" -RoutingDomain "Testec0db49f-6fc1-4a75-9905-e08c8dfa0a25"
#NAT-enabled gateway
$vmnetwork = get-scvmnetwork test
$vmnetworkgateway = get-SCVMNetworkGateway -VMNetwork $vmnetwork
$nat = get-scnatconnection -VMNetworkGateway $vmnetworkgateway
get-scnatrule -natconnection $nat
#Layer 3 gateway (direct route)
$outfile = "c:\log\vmnetworks.txt"
$vmns = get-scvmnetwork
foreach ($vmn in $vmns)
{if ($vmn.VMNetworkGateways[0] -ne $null -and $vmn.natconnections[0] -eq $null)
{$vmn.name |out-file -width 500 -filepath $outfile
$VmNetworkGateway = Get-SCVMNetworkGateway -Name $vmn.VMNetworkGateways[0] -vmnetwork
$vmn
}
}

#Step 5: Perform a network packet analysis