Param (
    [Parameter(Mandatory=$true,Position=1)]
    [String] $VM)

Write-Host "Retrieving VM Details - " -NoNewline
$SCVM = Get-SCVirtualMachine -Name $VM
Write-Host "Success" -ForegroundColor Green

Write-Host "Starting UP VM - " -NoNewline
$Empty = Start-SCVirtualMachine -VM $VM
Write-Host "Success" -ForegroundColor Green