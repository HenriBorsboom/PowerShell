Clear-Host
For ($timer = 1; $timer -lt 1000; $timer ++) {
    #$Decimal = "{0:D4}" -f $timer
    Write-Host (("{0:D4}" -f $timer) + "/1000") -ForegroundColor Cyan -NoNewline; Write-Host " - Size: " -NoNewline; Write-Host ("{0:N2}" -f ((Get-ChildItem "D:\Temp\Mtk_Droid_Tool_v2.5.3\backups\Vodafone-Smart-Tab-3G_141114_backup_151218-052338" | Measure-Object -Property Length -Sum).Sum / 1MB)) -ForegroundColor Yellow
    sleep 3
}
