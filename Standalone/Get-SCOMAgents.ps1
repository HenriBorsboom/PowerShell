Clear-Host

Import-Module OperationsManager
Get-SCOMAgent | Where-Object {$_.HealthState -eq "Success" -and $_.DisplayName -like "*.sysproza.net"} | Select DisplayName | Sort DisplayName