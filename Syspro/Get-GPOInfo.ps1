Clear-Host
Write-Host "Getting GPOs from Domain - " -NoNewline
    $GPOs = Get-GPO -All
Write-Host ($GPOs.Count.ToString() + " Found") -ForegroundColor Green

For ($i = 0; $i -lt $GPOs.Count; $i ++) {
    $OutFile = ('C:\Temp\GPO\' + $GPOs[$i].DisplayName + '.html')
    If (Test-Path $OutFile) { Remove-Item $OutFile -Force }
    Write-Host "Exporting " -NoNewline; Write-Host $GPOs[$i].DisplayName -ForegroundColor Yellow -NoNewline; Write-Host " to " -NoNewline; Write-Host $OutFile -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline 
        Get-GPOReport -Guid $GPOs[$i].Id -ReportType html | Out-File $OutFile -Encoding ascii -Force -NoClobber
    Write-Host "Complete" -ForegroundColor Green
}