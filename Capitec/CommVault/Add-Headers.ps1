$ReportFiles = Get-ChildItem 'C:\Temp\CommVault\CalculateReports\Reports'
For ($i = 0; $i -lt $ReportFiles.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $ReportFiles.Count.ToString() + ' - Processing ' + $ReportFiles[$i] + ' - ') -NoNewline
    $ReportContents = Get-Content $ReportFiles[$i].FullName
    ("FullName|Length|LastWriteTime|Mode"), $ReportContents | Set-Content ($ReportFiles[$i].Fullname + ".csv")
    Remove-Variable ReportContents
    [GC]::Collect()
    Write-Host "Complete" -ForegroundColor Green
}