Param (
    [Parameter(Mandatory=$true,Position=1)]
    [String] $VM)

Write-Host "Retrieving VM Details - " -NoNewline
$SCVM = Get-SCVirtualMachine -Name $VM
Write-Host "Success" -ForegroundColor Green

Write-Host "Shutting Down VM - " -NoNewline
$Empty = Stop-SCVirtualMachine -VM $VM -Shutdown
Write-Host "Success" -ForegroundColor Green