Clear-Host

$RootFolders = LS C:\ClusterStorage -Directory

ForEach ($RootFolder in $RootFolders) {
    cd $RootFolder.FullName
    
    $Folders = LS -Directory
    ForEach ($Directory in $Folders) {
        Write-Host ("Attempting to rename " + $Directory.Fullname + " - ") -ForegroundColor Yellow -NoNewline
        Try {
            Rename-Item $Directory.Fullname -NewName ($Directory.Fullname + ".old") -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}