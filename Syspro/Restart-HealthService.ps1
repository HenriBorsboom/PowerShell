Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $Computer)

$ErrorActionPreference = 'Stop'
$WarningPreference     = 'SilentlyContinue'
If ($Computer -eq "") {
    Restart-Service HealthService -Force
}
Else {
    Invoke-Command -ComputerName $Computer -ScriptBlock { Restart-Service HealthService -Force }
}