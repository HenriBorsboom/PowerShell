$DestinationFolder = "C:\Temp\NewMPs"

Clear-Host 
Write-Host "Getting MPS - " -NoNewline
    $MPs = Get-ChildItem -LiteralPath "C:\" -Include "*.mp", "*.mpb" -Recurse -Force -ErrorAction SilentlyContinue -Verbose
Write-Host "Complete"

For ($i = 0; $i -lt $MPs.Count; $i ++) {
    Write-Host (($i + 1).ToString() + "/" + $MPs.Count.ToString()) -ForegroundColor Cyan -NoNewline; Write-Host " - Copying " -NoNewline; Write-Host $MPs[$i].FullName -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
        Copy-Item -Path $MPs[$i].FullName -Destination $DestinationFolder -Force -ErrorAction Continue
    Write-Host "Complete"
}
