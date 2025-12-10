$Run = 'NextRun6'
$CSVReportPath = ('C:\Temp\Commvault\Reports\' + $Run)
$Reports = Get-ChildItem ('C:\Temp\Commvault\Reports\' + $Run)

For ($i = 0; $i -lt $Reports.Count; $i ++) {
    Write-Progress -PercentComplete (($i + 1) / $Reports.Count * 100) -Activity ('Redoing Reports - ' + (($i + 1) / $Reports.Count * 100) + '%') -ID 1
    [String[]] $Files = Get-Content $Reports[$i].FullName
    "FullName|Length|Attribute|CopyFlag" | Out-File ($CSVReportPath + '\' + $Reports[$i].BaseName + '.csv') -Encoding ascii
    For ($x = 0; $x -lt $Files.Count.ToString(); $x ++) {
        Write-Progress -PercentComplete (($x + 1) / $RestoreFiles.Count * 100) -Activity ('Getting File details - ' + (($x + 1) / $RestoreFiles.Count * 100) + '%') -ParentId 1
        #Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' | ' + ($x + 1).ToString() + '/' + $Files.Count.ToString() + ' - Processing ' + $Files[$i] + ' - ') -NoNewline
        $F_File = Get-Item $Files[$x]
        Try {
            $X_File = Get-Item $File.FullName.replace('F:', 'X:')
            If ($X_File.Mode.Contains('l')) {
                $CopyFlag = 'Backup is archvied'
            }
            Else {
                $CopyFlag = 'Unknown'
            }
        }
        Catch {
            $CopyFlag = 'File not in backup'
        }
        (($F_File.FullName.ToString(), $F_File.Length.ToString(), $F_File.LastWriteTime.ToString(), $F_File.Mode.ToString(), $CopyFlag) -join "|") | Out-File ($CSVReportPath + '\' + $Reports[$i].BaseName + '.csv') -Encoding ascii -Append
        #Write-Host "Complete"
    }
    Remove-Variable Files
    [GC]::Collect()
}