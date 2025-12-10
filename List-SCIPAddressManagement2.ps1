Param ($searchIP)
Clear-Host
Import-Module virtualmachinemanager

Function List-SCIPAddress {
    Param ($searchIP)
    Get-SCIPAddress | where Name -eq $SearchIP | Select Name,Description
}

Write-Host "Start"
List-SCIPAddress -searchIP $SearchIP
Write-Host "Sleep"
Sleep 5