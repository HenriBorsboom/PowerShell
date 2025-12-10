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
    Param ($TargetCluster)
    $WMIResults = Query-WMI -NameSpace '\root\MSCluster' -Class 'MSCluster_Cluster' -Property @('Name') -RemoteServer $TargetCluster
    Return $WMIResults
}
Function GetNodesState {
    $WMIResults = Query-WMI -NameSpace '\root\MSCluster' -Class 'MSCluster_Node' -Property @('Name','State') -RemoteServer $Global:ReturnedClusterName
    $ClusterNodes = @()
    ForEach ($Node in $WMIResults) {
        Switch ($WMIResults.State) {
            "-1"    { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "State Unknown" }) }
            "0"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Up" }) }
            "1"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Down" }) }
            "2"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Paused" }) }
            "3"     { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = "Joining" }) }
            Default { $ClusterNodes += ,(New-Object -TypeName PSObject -Property @{ Name = $Node.Name; State = $NodeStatus }) }
        }
    }
    Return ($ClusterNodes | Select Name, State)
}
Function GetClusterVMsState {
    Param ($ClusterNodes)
    $ClusterNodes = $Global:ReturnedNodes
    $ClusterVMs = @()
    ForEach ($Node in $ClusterNodes) {
        $WMIResults = Query-WMI -NameSpace 'root\MSCluster' -Query "select Name, State from MSCluster_ResourceGroup where grouptype = 111" -RemoteServer $Node.Name
        ForEach ($ClusterVM in $WMIResults) {
            Switch($ClusterVM.State) {
                "-1" { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "State Unknown" }) }
                "0"  { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "Online" }) }
                "1"  { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "Offline" }) }
                "2"  { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "Failed" }) }
                "3"  { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "Partial Online" }) }
                "4"  { $ClusterVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $ClusterVM.Name; HA = $True; State = "Pending" }) }
            }
        }
    }
    Return ($ClusterVMs | Select Name, HA, State)
}
Function GetClusterVolumes {
    Param ($TargetCluster)
    $TargetCluster = $Global:ReturnedClusterName
    $WMIResults = Query-WMI -NameSpace 'root\mscluster' -Class 'MSCluster_ClusterSharedVolume' -Property @('Name') -RemoteServer $TargetCluster
    Return $WMIResults
}
#endregion
#region Hyper-V
Function GetHyperVVMs {
    Param ($HyperVHosts)
    $HyperVHosts = $Global:ReturnedNodes
    $HyperVVMs = @()
    ForEach ($VMHost in $HyperVHosts) {
        $WMIResults = Query-WMI -NameSpace 'root\virtualization' -Query "select ElementName from Msvm_ComputerSystem where Caption= 'Virtual Machine'" -RemoteServer $VMHost
        ForEach ($HyperVVM in $WMIResults) {
            $HyperVVMs += ,(New-Object -TypeName PSObject -Property @{ Name = $WMIResults.Name; HA = $False; HyperVHost = $VMHost }) 
        }
    }
    Return ($HyperVVMs | Select Name, HA, HyperVHost)
}
Function CompareClustertoHyperV {
    Param ($ClusterVMs, $HyperVVMs)

    $StandaloneVMs = @()
    # Compare Cluster VM Array to Hyper-V VM Array
    ForEach ($HyperVVM in $HyperVVMs) {
        If (!$ClusterVMs.Contains($HyperVVM.Name)) { $StandaloneVMs += ,($HyperVVM)} # NOT HA VM}
    }
    Return $StandaloneVMs
}
Function GetVMSpecs {
    Param ($VMs)
    $VMs = $Global:ReturnedHyperVVMs
    $VMSpecs = @()
    ForEach ($VM in $VMs) {
        $WMIResults1 = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_ComputerSystem' -Property @('TotalPhysicalMemory', 'NumberOfProcessors') -RemoteServer $VM.Name
        $WMIResults2 = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_Processor' -Property @('Name') -RemoteServer $VM.Name
        $WMIResults3 = Query-WMI -NameSpace 'root\virtualization' -Query ("select ExternalDataRoot from Msvm_VirtualSystemGlobalSettingData where elementname= '" + $VM + "'") -RemoteServer $VM.Node
        $VMSpecs += ,(New-Object -TypeName PSObject -Property @{ 
            VMName = $VM.Name; 
            VMHost = $VM.Node; 
            Memory = $WMIResults1.TotalPhysicalMemory; 
            Processors = $WMIResults1.NumberOfProcessors
            ProccesorName = $WMIResults2.NamePr
            ExternalDataRoot = $WMIResults3.ExternalDataRoot
        } )
    }
    Return ($VMSpecs | Select VMName, VMHost, Memory, Processors, ProcessorName, ExternalDataRoot)
}
#endregion
#region Nodes
Function GetNodeSpecs {
    Param ($Nodes)
    $Nodes = $Global:ReturnedNodes
    $NodeSpecs = @()
    ForEach ($Node in $Nodes) {
        $WMIResults = Query-WMI -NameSpace 'root\cimv2' -Class 'Win32_ComputerSYstem' -Property @('TotalPhysicalMemory','NumberOfLogicalProcessors') -RemoteServer $Node
        $NodeSpecs += ,(New-Object -TypeName PSObject -Property @{
            Name = $Node.Name
            TotalPhysicalMemory = $WMIResults.TotalPhysicalMemory
            NumberOfLogicalProcessors = $WMIResults.NumberOfLogicalProcessors
        } )
    }
    Return ($NodeSpecs | Select Name, TotalPhysicalMemory, NumberOfLogicalProcessors)
}
#endregion

# Get the cluster name from hostname
$Global:ReturnedClusterName = GetClusterName -TargetCluster $TargetCluster
# Get the nodes and their status on the cluster
$Global:ReturnedNodes = GetNodesState 
# Get the VMs and their state hosted on the Cluster
$Global:ReturnedClusterVMs = GetClusterVMsState -ClusterNodes $Global:ReturnedNodes
# Get Cluster Volumes
$Global:ReturnedCSVVolumes = GetClusterVolumes -TargetCluster $Global:ReturnedClusterName
# Get VMs hosted on each node
$Global:ReturnedHyperVVMs = GetHyperVVMs -HyperVHosts $Global:ReturnedNodes
# Compare the list of Cluster VMs to Hyper-V Node VMs
$Global:StandaloneVMs = CompareClustertoHyperV -ClusterVMs $Global:ReturnedClusterVMs -HyperVVMs $Global:ReturnedHyperVVMs
# Get the specs of the VMs
$Global:ReturnedVMSpecs = GetVMSpecs -VMs $Global:ReturnedHyperVVMs
# Get the specs of the nodes
$Global:ReturnedNodeSpecs = GetNodeSpecs -Nodes $Global:ReturnedNodes