$Users = Get-ChildItem C:\Users

For ($i = 0; $i -lt $Users.Count; $i ++) {
    Write-host (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing ' + $Users[$i].BaseName + ' - ') -NoNewline
    If (Test-Path ($Users[$i].FullName + '\AppData\Local\CrashDumps')) {
        Write-Host 'Deleting files in CrashDumps - ' -ForegroundColor Green
        Write-Host ((Get-ChildItem ($Users[$i].FullName + '\AppData\Local\CrashDumps')).Count.ToString() + ' found') -ForegroundColor Magenta
        Get-ChildItem ($Users[$i].FullName + '\AppData\Local\CrashDumps') | Remove-Item
    }
    Else {
        Write-Host 'No CrashDumps located'
    }
}