$ErrorActionPreference = 'Stop'
Clear-Host

[DateTime] $Success3 = '2017-03-27 05:32:38 PM'
[DateTime] $Failure1 = '2017-03-27 05:39:50 PM'
[DateTime] $Failure2 = '2017-03-28 10:03:00 AM'

$LogsNames = Get-WinEvent -listLog *
$AllEvents = @()
For ($Index = 0; $Index -lt $LogsNames.Count; $Index ++) {
Write-Host (($Index + 1).ToString() + "/" + $LogsNames.Count.ToString() + " - Getting events in " + $LogsNames[$Index].LogName + " - ") -NoNewline
    Try {
        $Events = Get-WinEvent -LogName $LogsNames[$Index].LogName | Where-Object {$_.TimeCreated -ge $Success3 -and $_.TimeCreated -le $Failure1} 
        Write-Host ($Events.Count.ToString() + " Found") -ForegroundColor Green
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
    }
    Finally {
        $AllEvents += ,($Events)
    }
}
$AllEvents