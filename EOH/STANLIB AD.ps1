Import-Module ActiveDirectory
Import-Module FailoverClusters
Import-Module Hyper-V

Clear-Host

Write-Host "Getting AD Computers - " -NoNewline
$Servers = Get-ADComputer -Filter { Name -like '*' -and Enabled -eq $True -and OperatingSystem -like '*server*'} -Properties Name, OperatingSystem
Write-Host ($Servers.Count.ToString() + ' found') -ForegroundColor Green

For ($ServersI = 0; $ServersI -lt $Servers.Count; $ServersI ++) {
    Write-Host ("Testing " + $Servers[$ServersI].Name + " - ") -NoNewline
    If (Test-Connection -ComputerName $Servers[$ServersI].Name -Count 1 -Quiet) {
        Write-Host "Online" -ForegroundColor Green
    }
    Else {
        Write-Host "Offline" -ForegroundColor Red
    }

}