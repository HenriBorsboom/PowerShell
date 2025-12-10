Clear-Host
Import-Module virtualmachinemanager

Function List-SCIPAddress {
    Get-SCIPAddress | where Name -like '10.10.16.*' | Select Name,Description
}

List-SCIPAddress