Clear-Host
$Folders = Get-ChildItem C:\ClusterStorage
ForEach ($Folder in $Folders) {
    cd $Folder
    $SubFolders = Get-ChildItem
    ForEach ($Subfolder in $SubFolders) {
        Try {
            Write-Host ("Renaming Folder " + $SubFolder.FullName + " - ") -NoNewline
            ren $SubFolders[0].FullName -NewName ($SubFolder.FullName + ".old") -ErrorAction Stop
            Write-Host "Renamed" -ForegroundColor Red
        }
        Catch {
            Write-Host "In use" -ForegroundColor Green
        }
    }
    cd ..
}