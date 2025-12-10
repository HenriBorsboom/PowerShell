$ReportFiles = Get-ChildItem 'C:\temp\RoboCopy Reports'
$FolderCounter = 0
$FileCounter = 0
$FilesBusy = 0
For ($i = 0; $i -lt $ReportFiles.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $ReportFiles.Count.ToString() + ' - Getting Total Files of ' + $ReportFiles[$i].Name + ' - ') -NoNewline
    Try {
        $Folders = (((Get-Content $ReportFiles[$i].FullName) | select-string "Dirs :   ") -split '\s{2,}' | ForEach-Object { $_.Trim() })[2]
        $Files = (((Get-Content $ReportFiles[$i].FullName) | select-string "Files :   ") -split '\s{2,}' | ForEach-Object { $_.Trim() })[2]
        #$ValueFound = ((Get-Content $ReportFiles[$i].FullName)[-5] -split '\s{2,}' | ForEach-Object { $_.Trim() })[2]
        Write-Host ("Folders: " + $Folders.ToString() + ' - ') -NoNewline -ForegroundColor Green
        Write-Host ("Files: " + $Files.ToString()) -ForegroundColor Green
        
    }
    Catch {
        Write-Host "File still busy" -ForegroundColor Red
        $Files = 0
        $Folders = 0
        $FilesBusy += 1
    }
    Finally {
        $FolderCounter += $Folders
        $FileCounter += $Files
    }
}
Write-Host ("Folders            : " + $FolderCounter.ToString()) -ForegroundColor Yellow
Write-Host ("Files              : " + $FileCounter.ToString()) -ForegroundColor Yellow
Write-Host ("Files Busy         : " + $FilesBusy.ToString()) -ForegroundColor Yellow
Write-Host ("Robocopy Processes : " + (get-process robocopy).Count.ToString()) -ForegroundColor Yellow