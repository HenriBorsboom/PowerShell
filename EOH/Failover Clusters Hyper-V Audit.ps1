Clear-Host
$Properties = @("Name", "State", "CPUUsage(%)", "MemoryAssigned(M)", "Uptime", "Status", "ComputerName")

Import-Module FailoverClusters
Write-Host ("Getting cluster objects in " + $env:USERDOMAIN + " - ") -NoNewline
#Get-Cluster -Domain $env:USERDOMAIN
$Clusters = Get-Cluster -Domain $env:USERDOMAIN
Write-Host ($Clusters.Count.ToString() + " Found")

$AllVMS = @()
ForEach ($Cluster in $Clusters) {
    # Get-ClusterNode -Cluster $Cluster.Name
    Write-Host ("Getting Cluster Nodes for " + $Cluster.Name + " - ") -NoNewline
    $ClusterNodes = Get-ClusterNode -Cluster $Cluster.Name
    Write-Host ($ClusterNodes.Count.ToString() + " Found")
    ForEach ($Node in $ClusterNodes) {
        Write-Host ("Getting VMs on " + $Node + " - ") -NoNewline
        $VMS = Get-VM -ComputerName $Node | Select $Properties
        Write-Host ($VMS.Count.ToString() + " Found")
        $AllVMS += $VMS
    }
}

$AllVMS | Select $Properties | Format-Table -AutoSize