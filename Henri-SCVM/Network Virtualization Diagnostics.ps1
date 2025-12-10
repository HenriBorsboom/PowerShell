Clear-Host

$Servers = @(
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

Function Get-VMSwitches {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Servers)

    Write-Host "Collect VMSwitch Config" -ForegroundColor Yellow
    $VMSwitches = @()
    ForEach ($Server in $Servers) {
        Write-Host "|-- $Server" -ForegroundColor Yellow
        $ServerSwitches = Get-VMSwitch -ComputerName $Server | Get-VMSwitchExtension | Where-Object { $_.Name -match "Microsoft VMM DHCP*" } #| Format-Table Computername, Switchname, Name, Enabled, Running -AutoSize
        ForEach ($VMSwitch in $ServerSwitches) {
            $VMSwitchInfo = New-Object PSObject -Property @{
                Computername                = $VMSwitch.Computername
                Switchname                  = $VMSwitch.Switchname
                Name                        = $VMSwitch.Name
                Enabled                     = $VMSwitch.Enabled
                Running                     = $VMSwitch.Running
            }
            $VMSwitches = $VMSwitches + $VMSwitchInfo
        }
    }
    Return $VMSwitches
}
Function Get-NetVirtPA {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Servers)

    Write-Host "Getting Network Virtualization Provider Address" -ForegroundColor Yellow
    $NetworkVirtualizationProviderAddresses = @()
    ForEach ($Server in $Servers) {
        Write-Host "|-- $Server" -ForegroundColor Yellow
        $Results = Invoke-Command -ComputerName $Server -ScriptBlock { Get-NetVirtualizationProviderAddress }
        ForEach ($VirtPA in $Results) {
            $PA = New-Object PSObject -Property @{
                PSComputerName      = $VirtPA.PSComputerName
                ProviderAddress     = $VirtPA.ProviderAddress
                InterfaceIndex      = $VirtPA.InterfaceIndex
                PrefixLength        = $VirtPA.PrefixLength
                VlanID              = $VirtPA.VlanID
                AddressState        = $VirtPA.AddressState
                MACAddress          = $VirtPA.MACAddress
                ManagedByCluster    = $VirtPA.ManagedByCluster
            }
            $NetworkVirtualizationProviderAddresses = $NetworkVirtualizationProviderAddresses + $PA
        }
    }
    Return $NetworkVirtualizationProviderAddresses
}
Function Get-NetVirt {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Servers)

    Write-Host "Getting Network Virtualization Customer Route" -ForegroundColor Yellow
    $NetVirtualizationCustomerRoutes = @()
    ForEach ($Server in $Servers) {
        Write-Host "|-- $Server" -ForegroundColor Yellow
        $ServerVirtRoutes = Get-NetVirtualizationCustomerRoute -CimSession $Server
        ForEach ($VirtRoute in $ServerVirtRoutes) {
            $VirtualRoutes = New-Object PSObject -Property @{
                RoutingDomainID     = $VirtRoute.RoutingDomainID
                VirtualSubnetID     = $VirtRoute.VirtualSubnetID
                DestinationPrefix   = $VirtRoute.DestinationPrefix
                NextHop             = $VirtRoute.NextHop
                Metric              = $VirtRoute.Metric
                PSComputerName      = $VirtRoute.PSComputerName
            }
            $NetVirtualizationCustomerRoutes = $NetVirtualizationCustomerRoutes + $VirtualRoutes
        }
    }
    Return $NetVirtualizationCustomerRoutes
}
Function Get-VMLookupRecords {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Servers)

    Write-Host "Getting VMs" -ForegroundColor Yellow
    $NetVirtualizationLookupRecords = @()
    ForEach ($Server in $Servers) {
        Write-Host "|-- $Server" -ForegroundColor Yellow
        $ServerVMs = Get-VM -ComputerName $Server
        Write-Host "|-- Getting Network Virtualization Lookup Records" -ForegroundColor Yellow
        ForEach ($VM in $ServerVMs) {
            Write-Host ("    |-- " + $VM.Name) -ForegroundColor Yellow
            $VMRecords = Invoke-Command -ComputerName $Server -ScriptBlock { Get-NetVirtualizationLookupRecord | Where-Object { $_.VMName -match $VM.Name } }
            ForEach ($VMRecord in $VMRecords) {
                $LookupRecord = New-Object PSObject -Property @{
                    CustomerAddress     = $VMRecord.CustomerAddress
                    VirtualSubnetID     = $VMRecord.VirtualSubnetID
                    MACAddress          = $VMRecord.MACAddress
                    ProviderAddress     = $VMRecord.ProviderAddress
                    CustomerID          = $VMRecord.CustomerID
                    Context             = $VMRecord.Context
                    Rule                = $VMRecord.Rule
                    VMName              = $VMRecord.VMName
                    UseVmMACAddress     = $VMRecord.UseVmMACAddress
                    Type                = $VMRecord.Type
                    PSComputerName      = $VMRecord.PSComputerName
                }
                $NetVirtualizationLookupRecords = $NetVirtualizationLookupRecords + $LookupRecord
            }
        }
    }
    Return $NetVirtualizationLookupRecords
}

#Get-VMSwitches -Servers $Servers | Format-Table Computername, Switchname, Name, Enabled, Running -AutoSize
Get-NetVirtPA -Servers $Servers | Format-Table PSComputerName, ProviderAddress, InterfaceIndex, PrefixLength, VlanID, AddressState, MACAddress, ManagedByCluster
#Get-VMLookupRecords -Servers $Servers | Format-Table CustomerAddress, VirtualSubnetID, MACAddress, ProviderAddress, CustomerID, Context, Rule, VMName, UseVmMACAddress, Type, PSComputerName