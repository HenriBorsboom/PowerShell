Function Check-PlanetPress {
    Clear-Host
    $Source = '\\signapprd01\e$\PlanetPressProcessing'

    $Folders = Get-ChildItem -Path $Source 
    ForEach ($Folder in $Folders) {
        Write-Host $Folder.Name -ForegroundColor Green
        $SubFolders = Get-ChildItem -Path $Folder.Fullname -Directory
        $MainCount = (Get-ChildItem -Path $Folder.FullName -File).Count
        Write-Host ("|- ") -NoNewline
        Write-Host $MainCount.ToString() -NoNewline -ForegroundColor Yellow
        Write-Host (' - ' + $Folder.Name)

        ForEach ($SubFolder in $SubFolders) {
            If ($SubFolder.Name -eq 'Success') {
                Continue
            }
            Else {
                $FileCount = (Get-ChildItem -Path $SubFolder.FullName -File).Count
                    Write-Host ("|- ") -NoNewline
                    Write-Host $FileCount.ToString() -NoNewline -ForegroundColor Yellow
                    Write-Host (' - ' + $SubFolder.Name)
            }
        }
        Write-Host ""
    }
}

While ($True) {
    Check-PlanetPress
    Write-Host ""
    Write-Host "Waiting 5 seconds for refresh..." -ForegroundColor Cyan
    Start-Sleep -Seconds 5
}