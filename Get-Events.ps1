#Variables
$ErrorActionPreference = 'Stop'
[DateTime] $StartDate = '2019/07/29 12:00' # (Get-Date).AddHours(-1)
[DateTime] $EndDate   = '2019/07/29 12:17' #  Get-Date

Clear-Host
Write-Host "Getting All System logs with records - " -NoNewline
$ActiveLogs = Get-WinEvent -ListLog * | Where-Object {$_.RecordCount -gt 0}
Write-Host ($ActiveLogs.Count.ToString() + ' logs found')

$AllEvents = @()
$EventCount = 0
For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
    Write-Host ("Getting Logs from " + $ActiveLogs[$LogI].LogName + " - ") -NoNewLine
    $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate} -ErrorAction SilentlyContinue
    Write-Host ($LogEvents.Count.ToString() + ' found')
    $AllEvents += ,($LogEvents)
    $EventCount += $LogEvents.Count
    $LogEvents = 0
}
Write-Host ("Total events recorded: " + $EventCount.ToString())
$AllEvents | Format-List | Out-File ($Env:TEMP + '\Events_' + '{0:yyyy-mm-dd_HH.mm.ss}' -f (Get-Date) + '.txt') -Force -Encoding ascii
$AllEvents | Format-List
Write-Host ("Events saved to: ")
Write-Host ("  " + $Env:TEMP + '\Events_' + '{0:yyyy-mm-dd_HH.mm.ss}' -f (Get-Date) + '.txt')