Param (
    [Parameter(Mandatory=$True)]
    [String] $SourceFolder)

#$SourceFolder = 'C:\Users\henri.borsboom\Documents\EOH\Clients\GIBS\Daily Checks'
Write-Color -Text 'Getting files from ', $SourceFolder, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
$SourceFiles = Get-ChildItem $SourceFolder -File
Write-Color -Text $SourceFiles.Count, ' Found' -ForegroundColor Cyan, Cyan

For ($i = 0; $i -lt $SourceFiles.Count; $i ++) {
    Write-Color -IndexCounter $i -TotalCounter $SourceFiles.Count -Text 'Checking ', $SourceFiles[$i].Fullname, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    If ($SourceFiles[$i].BaseName.Contains("Infrastucture")) {
        Rename-Item -Path $SourceFiles[$i].FullName -NewName ($SourceFiles[$i].FullName.Replace("Infrastucture", "Infrastructure"))
        Write-Color -Text 'Renamed' -ForegroundColor Yellow
    }
    Else {
        Write-Color -Text 'Skipped' -ForegroundColor Green
    }
}



