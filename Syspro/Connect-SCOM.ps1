Param (
    [Parameter(Mandatory=$True, Position=1)][ValidateSet("2012", "2016", "SYSJHBOPSMGR", "SYSJHBSCOM01")]
    [String] $SCOM)

Import-Module OperationsManager
    Switch ($SCOM) {
        "2012"         { New-SCOMManagementGroupConnection -ComputerName "SYSJHBOPSMGR.sysproza.net" }
        "SYSJHBOPSMGR" { New-SCOMManagementGroupConnection -ComputerName "SYSJHBOPSMGR.sysproza.net" }
        "2016"         { New-SCOMManagementGroupConnection -ComputerName "SYSJHBSCOM01.sysproza.net" }
        "SYSJHBSCOM01" { New-SCOMManagementGroupConnection -ComputerName "SYSJHBSCOM01.sysproza.net" }
}