Clear-Host
Import-Module virtualmachinemanager

Function List-SCIPAddress {
    Get-SCIPAddress | Select Name,Description
}

List-SCIPAddress