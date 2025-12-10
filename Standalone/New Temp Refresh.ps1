Function 1 {
$Hosts = @(
    "NRAZUREVMH101", `
    "NRAZUREVMH102", `
    "NRAZUREVMH103", `
    "NRAZUREVMH104", `
    "NRAZUREVMH105", `
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")

$HostsCounter = 0
$HostsCount = $Hosts.Count
ForEach ($VMHost in $Hosts) {
    Write-Host ($HostsCounter + "/" + $HostsCount + " - " + $VMHost)
    $SCVMHost = Get-SCVMHost -ComputerName $VMHost
    Read-SCVMHost -VMHost $SCVMHost | Out-Null
    $VMs = Get-SCVirtualMachine -VMHost $SCVMHost
    
    $VMSCounter = 0
    $VMsCount = $VMs.Count
    ForEach ($VM in $VMs) {
        Write-Host ($VMSCounter + "/" + $VMsCount + " - " + $VM.Name)
    Get-SCVirtualMachine -Name $VM.Name | Read-SCVirtualMachine | Out-Null
    }
}
}
Function 2 {
$ErrorActionPreference = "Stop"
Function Refresh-SCVMCluster {
    Param ($Cluster)
    
    ForEach ($Node in ((Get-ClusterNode -Cluster $Cluster).Name | Sort)) {
        Write-Host $Node
        Get-SCVMHost -ComputerName $Node | Read-SCVMHost | Get-SCVirtualMachine | Read-SCVirtualMachine | Out-Null
    }
}

#Refresh-SCVMCluster -Cluster "NRAZUREVMHC102"
Refresh-SCVMCluster -Cluster "NRAZUREDBSC102"

Refresh-SCVMCluster -Cluster "NRAPCSYSC101"
Refresh-SCVMCluster -Cluster "NRAZUREVMHC103"
#Refresh-SCVMCluster -Cluster "NRAPCDBSC101"
}
Function 3 {
Get-SCVMHost -ComputerName "NRAZUREVMH102" | Read-SCVMHost | Get-SCVirtualMachine | Read-SCVirtualMachine | Out-Null
}
Function 4 {
Clear-Host

Write-Host "Refreshing NRAZUREVMH101"
$VMH101 = Get-SCVMHost -ComputerName "NRAZUREVMH101"; Read-SCVMHost -VMHost $VMH101 | Out-Null
Write-Host "Refreshing NRAZUREVMH102"
$VMH102 = Get-SCVMHost -ComputerName "NRAZUREVMH102"; Read-SCVMHost -VMHost $VMH102 | Out-Null

Write-Host "Getting NRAZUREVMH101 VMs"
$VMs1 = Get-SCVirtualMachine -VMHost $VMH101
Write-Host "Getting NRAZUREVMH102 VMs"
$VMs2 = Get-SCVirtualMachine -VMHost $VMH102

Write-Host "Refreshing VMS"
ForEach ($VM in $VMs1) { 
Write-Host $VM.Name; Get-SCVirtualMachine -VMHost $VMH101 | Read-SCVirtualMachine }
ForEach ($VM in $VMs2) { Write-Host $VM.Name; Get-SCVirtualMachine | Read-SCVirtualMachine | Out-Null }

$VMs1.Name
$VMs2.Name
}
