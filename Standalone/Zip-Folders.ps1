Function ZipFolder {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $FolderPath, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $ZipPath)

    $Folders = Get-ChildItem $FolderPath

    $ZipFiles = {
        Param ($ZipFileName, $SourceDirectory)
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        [System.IO.Compression.ZipFile]::CreateFromDirectory($SourceDirectory, $ZipFileName, $CompressionLevel, $false)
    }
    
    $Counter = 1
    $Count = $Folders.Count
    
    #ForEach ($Folder in $Folders) {
        $ZipFile = ($ZipPath +"\" + 'File' + ".zip")
        $SourceDir = $FolderPath
        Write-Host ($Counter.ToString() + "/" + $Count.toString()) -ForegroundColor Cyan -NoNewline; Write-Host " - Compressing " -NoNewline; Write-Host $SourceDir.ToString().ToUpper() -ForegroundColor Yellow -NoNewline; Write-Host " to " -NoNewline; Write-Host $ZipFile.ToString().ToUpper() -ForegroundColor Yellow -NoNewline; Write-Host " " -NoNewline
        Start-Job -ScriptBlock $ZipFiles -ArgumentList $ZipFile, $SourceDir | Out-Null
        While ((get-job).State -eq "Running") {
            Write-Host "-" -NoNewline -ForegroundColor DarkYellow
            sleep 1
        }
        If ((Get-Job).State -eq "Completed") { Write-Host " Complete" -ForegroundColor Green }
        Else                                 { Write-Host (" " + (Get-Job).State) -ForegroundColor Red }
        Get-Job | Remove-Job
        $Counter ++
    #}
}
Clear-Host
ZipFolder -FolderPath C:\Games -ZipPath "C:\Temp\Dell"