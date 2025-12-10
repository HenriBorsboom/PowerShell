# New-PSDrive -Name CommVault -PSProvider FileSystem -Root '\\BACKUPSERVER01\FILESERVER01\Restore' -Credential (Get-Credential)
$ErrorActionPreference = 'Stop'
Function Send-Notification {
    $Message | Out-File '\\CBFP01\Temp\ScriptComplete.txt' -Encoding ascii -Force

}
Function Control-Stop {
    If ($psISE -ne $null) {
        # in ISE
    }
    Else {
        If ([System.Console]::KeyAvailable) {
            $key = [System.Console]::ReadKey($True)
            if ($Key.Key -eq 'Escape') {
                Write-Host "Script Execution stopped by user"
                $Message = ("Controlled stop of CommVault file restores. Last I: " + (Get-Content $ResumeIFile) + " - Last X: " + (Get-Content $ResumeXFile))
                Send-Notification -Message $Message            
                Remove-Variable RestoreFiles
                [GC]::Collect()
                break
            }
        }
    }
}
$Reports = Get-ChildItem 'D:\Temp\CommVault\Copy_Reports'-File
$TargetRestoreFolder = 'E:\'
$ResumeIFile = 'D:\Temp\CommVault\ResumeI.txt'
$ResumeXFile = 'D:\Temp\CommVault\ResumeX.txt'
[Int] $ResumeI = Get-Content $ResumeIFile
[Int] $ResumeX = Get-Content $ResumeXFile

If ($ResumeI -eq $null -or $ResumeI -eq '') {
    $ResumeI = 0
}
If ($ResumeX -eq $null -or $ResumeX -eq '') {
    $ResumeX = 0
}

$StartTime = Get-Date
For ($i = $ResumeI; $i -lt $Reports.Count; $i ++) {
    $i | Out-File $ResumeIFile -Encoding ascii -Force    
    Write-Progress -PercentComplete ($i / $Reports.Count * 100) -Activity ('Copying Reports - ' + ($i / $Reports.Count * 100) + '%') -ID 1
    $ArchiveReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_ArchiveReport.txt')
    $MissingReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_MissingReport.txt')
    Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' - Getting Contents of ' + $Reports[$i])
    [String[]] $RestoreFiles = Get-Content $Reports[$i].FullName
    For ($x = $ResumeX; $x -lt $RestoreFiles.Count; $x ++) {
        $x | Out-File $ResumeXFile -Encoding ascii -Force
        Write-Progress -PercentComplete ($x / $RestoreFiles.Count * 100) -Activity ('Copying Files - ' + ($x / $RestoreFiles.Count * 100) + '%') -ParentId 1
        Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' | ' + ($x + 1).ToString() + '/' + $RestoreFiles.Count.ToString() + ' Processing ' + $RestoreFiles[$x] + ' - ') -NoNewline
        $RestoreFile = $RestoreFiles[$x].Replace('F:\FILESERVER01\Restore\', 'E:\')
        If (Test-Path -LiteralPath $RestoreFile) {
            If ((Get-Item -LiteralPath $RestoreFile).Mode -like '*l*') {
                $RestoreFile | Out-File $ArchiveReportFile -Encoding ascii -Append
                Write-Host 'Archived' -ForegroundColor Yellow
            }
            Else {
                $RestorePath = $RestoreFile.Replace('F:\FILESERVER01\D\', '') -split '\\'
                For ($y = 0; $y -le ($RestorePath.Count - 2); $y ++) {
                    If (Test-Path -LiteralPath ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\'))) {
                        #folder exists
                    }
                    Else {
                        New-Item ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\')) -ItemType Directory | Out-Null
                    }
                }
                If (Test-Path -LiteralPath ($RestoreFile.Replace('F:\FILESERVER01\D', $TargetRestoreFolder))) {
                    If ((Get-ChildItem $RestoreFile).Length -gt (Get-ChildItem ($RestoreFile.Replace('F:\FILESERVER01\D', $TargetRestoreFolder))).Length) {
                        Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('F:\FILESERVER01\D', $TargetRestoreFolder)) -Force
                        Write-Host 'Newer Copied' -ForegroundColor Cyan
                    }
                    Else {
                        Write-Host 'Skipped' -ForegroundColor Green
                    }
                }
                Else {
                    Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('F:\FILESERVER01\D', $TargetRestoreFolder))
                    Write-Host 'Copied' -ForegroundColor Green
                }
            }

        }
        Else {
            $RestoreFile | Out-File $MissingReportFile -Encoding ascii -Append
            Write-Host 'Missing' -ForegroundColor Red
        }
        Control-Stop
    }
    0 | Out-File $ResumeXFile -Encoding ascii -Force
    Remove-Variable RestoreFiles
    [GC]::Collect()
}
$EndTime = Get-Date
$Message = ("Start time: " + $StartTime.ToString() + ' - End Time: ' + $EndTime.ToString() + ' - Duration: ' + (($EndTime - $StartTime) -f '{0:HH:mm:ss}') + ' - Restore Complete')
Send-Notification -Message $Message