$ReportFiles = Get-ChildItem 'C:\Temp\CommVault\CalculateReports\Reports\*.txt'
$MasterFile = 'C:\Temp\CommVault\CalculateReports\Reports\Master.csv'
"Fullname|Length|LastWrittenTime|Mode" | Out-File $MasterFile
For ($i = 0; $i -lt $ReportFiles.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $ReportFiles.Count.ToString() + ' - Processing ' + $ReportFiles[$i] + ' - ') -NoNewline
    $ReportContents = Get-Content $ReportFiles[$i].FullName
    $ReportContents | Add-Content $MasterFile
    Remove-Variable ReportContents
    [GC]::Collect()
    Write-Host "Complete" -ForegroundColor Green
}