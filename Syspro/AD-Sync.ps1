Clear-Host

$Source = $env:COMPUTERNAME
$Destinations = @(
    "SYSJHBDC"
    "SYSCTDC"
    "SYSDBNDC"
    "SYSPRDDCINFRA1"
    "SYSPRO-DCVM")

$Domain = "DC=sysproza,DC=net"
Write-Host ("Running on: " + $env:COMPUTERNAME) -ForegroundColor Yellow
ForEach ($Destination in $Destinations) {
    If ($Destination -ne $Source) {
        Write-Host "Syncing from $Source to $Destination - " -NoNewline
        $Results = repadmin /replicate $Destination $Source $Domain /full
        Write-Host $Results
    }
}