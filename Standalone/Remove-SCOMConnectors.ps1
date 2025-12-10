$SCOMConnectors = Get-SCOMConnector | Where Name -like "*SCVMM*"
ForEach ($Connector in $SCOMConnectors) {
    Write-Host $Connector.Name
    Remove-SCOMConnector -Connector $Connector
}