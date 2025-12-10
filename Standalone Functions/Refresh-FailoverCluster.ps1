Function Refresh-FailoverCluster {
    Param (
        [Parameter(Mandatory=$true)] 
        [String] $ClusterName)

    Import-Module FailoverClusters
    Get-ClusterResource -c $ClusterName | where {$_.resourcetype.name -eq 'virtual machine configuration'} | Update-ClusterVirtualMachineConfiguration
}
