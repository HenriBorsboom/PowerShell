Function Query-WMI {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $RemoteServer, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $NameSpace, `
        [Parameter(Mandatory=$True, Position=3, ParameterSetName="Properties")]
        [String] $Class, `
        [Parameter(Mandatory=$True, Position=4, ParameterSetName="Properties")]
        [String[]] $Property, `
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="Query")]
        [String] $Query)


        #Get-WmiObject -Query "select name from win32_service where name like '%int%'" -Namespace 'root\cimv2'

    $CurrentErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference ='Stop'
    Try {
        $WMIResults = Get-WmiObject -Namespace $NameSpace -Class $Class -Property $Property -ErrorAction Stop
    }
    Catch {
        Write-Host "FAILURE!!!" -ForegroundColor Red
        Write-Host $_
    }
    Finally {
        If ($WMIResults -eq $null) { $WMIResults =  $False }
    }
    $ErrorActionPreference = $CurrentErrorActionPreference
    Return $WMIResults
}
#region Cluster
Function GetClusterName {
    $WMIResults = Query-WMI -NameSpace '\root\MSCluster' -Class 'MSCluster_Cluster' -Property @('Name') -RemoteServer ''
}
Function GetNodesState {
    $WMIResults = Query-WMI -NameSpace '\root\MSCluster' -Class 'MSCluster_Node' -Property @('Name','State') -RemoteServer ''
    Switch ($WMIResults.State) {
        "-1"    { "State Unknown" }
        "0"     { "Up" }
        "1"     { "Down" }
        "2"     { "Paused" }
        "3"     { "Joining" }
        Default { $NodeStatus }
    }
}
Function GetClusterVMsState {
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Query "select Name, State from MSCluster_ResourceGroup where grouptype = 111" -RemoteServer ''
    Switch($WMIResults.State) {
        "-1" { "State Unknown" }
        "0"  { "Online" }
        "1"  { "Offline" }
        "2"  { "Failed" }
        "3"  { "Partial Online" }
        "4"  { "Pending" }
    }
}
Function GetClusterCurrentOwner {
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Query ("select GroupComponent from MSCluster_NodeToActiveGroup where PartComponent= 'MSCluster_ResourceGroup.Name=""" + $RemoteServer + """'")  -RemoteServer ''
}
Function GetClusterAutoStart {
    $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Query ("select PersistentState from MSCluster_ResourceGroup where Name = '" + $RemoteServer + "'") -RemoteServer ''
}
Function GetClusterVolumes {
    $WMIResults = Query-WMI -NameSpace 'root\mscluster' -Class 'MSCluster_ClusterSharedVolume' -Property @('Name') -RemoteServer ''
}
#endregion
#region Hyper-V
Function GetHyperVVMs {
    $WMIResults = Query-WMI -NameSpace 'root\virtualization' -Query "select * from Msvm_ComputerSystem where Caption= 'Virtual Machine'" -RemoteServer ''
}
Function CompareClustertoHyperV {
    # Compare Cluster VM Array to Hyper-V VM Array
}
Function GetVMSpecs {
    $WMIResults1 = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_ComputerSystem' -Property @('TotalPhysicalMemory', 'NumberOfProcessors') -RemoteServer ''
    $WMIResults2 = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_Processor' -Property @('ExternalDataRoot') -RemoteServer ''
    $WMIResults3 = Query-WMI -NameSpace 'root\virtualization' -Query ("select * from Msvm_VirtualSystemGlobalSettingData where elementname= '" + $VMName + "'") -RemoteServer ''
}
#endregion
#region Nodes
Function GetNodeSpecs {
    $WMIResults = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_ComputerSYstem' -Property @('TotalPhysicalMemory','NumberOfLogicalProcessors') -RemoteServer ''
}
#endregion

# Get the cluster name from hostname
# Get the nodes and their status on the cluster
# Get the status of the nodes
# Get the VMs and their state hosted on the Cluster
# Get Current Owner of Cluster Group
# Get Cluster Auto Start
# Get Cluster Volumes
# Get VMs hosted on each node
# Compare the list of Cluster VMs to Hyper-V Node VMs
# Get the specs of the VMs
# Get the specs of the nodes