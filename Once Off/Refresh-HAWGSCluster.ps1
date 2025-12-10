Write-Host "Getting Cluster - " -NoNewline
$Cluster = Get-SCVMHostCluster -Name NRAZUREDBSC102
Write-Host "Complete" -ForegroundColor Green

Write-Host "Getting Host 1 - " -NoNewline
$Host1 = Get-SCVMHost -ComputerName NRAZUREVMH104
Write-Host "Complete" -ForegroundColor Green

Write-Host "Getting Host 2 - " -NoNewline
$Host2 = Get-SCVMHost -ComputerName NRAZUREVMH105
Write-Host "Complete" -ForegroundColor Green

Write-Host "Getting VMs on Host 1 - " -NoNewline
$Host1VM = Get-SCVirtualMachine -VMHost $Host1
Write-Host "Complete" -ForegroundColor Green

Write-Host "Getting VMs on Host 2 - " -NoNewline
$Host2VM = Get-SCVirtualMachine -VMHost $Host2

Write-Host "Get the Network Service - " -NoNewline
$NetworkService = Get-SCNetworkService -Name "Highly Available Windows Gateway Server"
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read the Cluster - " -NoNewline
$empty = Read-SCVMHostCluster -VMHostCluster $Cluster
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read Host 1 - " -NoNewline
$empty = Read-SCVMHost -VMHost $Host1
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read Host 2 - " -NoNewline
$empty = Read-SCVMHost -VMHost $Host2
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read the VM on Host 1 - " -NoNewline
$empty = Read-SCVirtualMachine -VM $Host1VM
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read the VM on Host 2 - " -NoNewline
$empty = Read-SCVirtualMachine -VM $Host2VM
Write-Host "Complete" -ForegroundColor Green

Write-Host "Read the Network Service - " -NoNewline
$empty = Read-SCNetworkService -NetworkService $NetworkService
Write-Host "Complete" -ForegroundColor Green
