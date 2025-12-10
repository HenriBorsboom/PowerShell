Clear-Host
$SourceServers = @(
    'SYSJHBDC'
    'SYSPRO-DCVM'
    'SYSCTDC'
    'SYSDBNDC'
    'SYSPRDDCINFRA1')
$DestinationServers = @(
    'SYSJHBDC'
    'SYSPRO-DCVM'
    'SYSCTDC'
    'SYSDBNDC'
    'SYSPRDDCINFRA1')
$NamingContext = '"DC=sysproza,DC=net"'

$AllResults = @()
For ($SourceIndex = 0; $SourceIndex -lt $SourceServers.Count; $SourceIndex ++) {
    For ($DestinationIndex = 0; $DestinationIndex -lt $DestinationServers.Count; $DestinationIndex ++) {
        Write-Host ("Replicating from: " + $SourceServers[$SourceIndex] + " to " + $DestinationServers[$DestinationIndex] + " - ") -NoNewLine
        If ($DestinationServers[$DestinationIndex] -ne $SourceServers[$SourceIndex]) {
            $Expression = ("RepAdmin /Replicate " + $DestinationServers[$DestinationIndex] + " " + $SourceServers[$SourceIndex]  + " " + $NamingContext + " /Force")
            $Result = Invoke-Expression $Expression
            $AllResults += (New-Object -TypeName PSObject -Property @{
                Source = $SourceServers[$SourceIndex]
                Destination = $DestinationServers[$DestinationIndex]
                Expression = $Expression
                Result = $Result
            })
            Write-Host ("Complete " + $Result) -ForegroundColor Green
        }
        Else {
            Write-Host "Skipped" -ForegroundColor Yellow
        }
    }
}
Write-Host
Write-Host
Write-Host "Full Results" -ForegroundColor DarkCyan
$AllResults | Format-Table -AutoSize