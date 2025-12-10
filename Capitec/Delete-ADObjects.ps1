$Servers = Import-Csv 'c:\temp\ad-inactiveservers.csv' -Delimiter ";"
$Errors = @()
ForEach ($Server in $Servers) {
    $ADObject = Get-ADComputer $Server.Name -Properties Enabled
    If ($ADObject.Enabled -eq $False) {
        Remove-ADComputer $Server
    }
    Else {
        Write-Host ($Server.Name + " is enabled")
        $Errors += ($Server.Name + " is enabled")
    }
}
$Errors | Export-Csv -Path ('c:\temp\AD-InactiveServers_Errors ' + (get-date -f "yyyy-MM-dd") + '.csv') -Force -NoClobber -NoTypeInformation -Encoding ASCII -Delimiter ';'