Clear-Host
$ErrorActionPreference = 'Stop'
$WarningPreference     = 'SilentlyContinue'
$Logs = Get-WinEvent -ListLog *
For ($i = 0; $i -lt $Logs.Count; $i ++) {
    Try {
        Write-Host (($i + 1).ToString() + '/' + $Logs.Count.ToString() + ' - ' + $Logs[$i].LogName + ' - ') -NoNewline
        Clear-EventLog $Logs[$i].LogName
        Write-Host 'Complete' -ForegroundColor Green
    }
    Catch { Write-Host $_ -ForegroundColor Red }
}