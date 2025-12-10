$Servers = Get-ADComputer -Filter {ObjectClass -eq "computer"}
$Servers = $Servers | Sort Name
$Servers = $Servers | Select -Unique
$Servers = $Servers.Name
Clear-Host
ForEach ($Server in $Servers) {
    Write-Host $Server -ForegroundColor Green
    ICM $Server {Get-NetFirewallProfile} | Select Name,Enabled | Where Enabled -eq "True"
    Write-host "---------------------------------------------------" -ForegroundColor Yellow
    Write-Host
}
