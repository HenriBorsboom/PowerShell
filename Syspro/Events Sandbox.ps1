$ErrorActionPreference = 'Stop'
Clear-Host

[DateTime] $Success3 = (Get-Date).AddMinutes(-60)
[DateTime] $Failure1 = (Get-Date)

$LogsNames = Get-WinEvent -listLog *
$AllEvents = @()
$Events = Get-WinEvent -FilterHashtable @{Logname=$LogsNames[1].LogName; StartTime=$Success3; EndTime=$Failure1}

<#
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
#>