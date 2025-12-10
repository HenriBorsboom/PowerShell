Clear-Host
Write-Host "Collecting APKs - " -NoNewline
$APKs = Get-ChildItem -Path "D:\" -Recurse -Include "*.apk" -Force -ErrorAction SilentlyContinue
Write-Host "Complete" -ForegroundColor Green
$Counter = 1
$Count = $APKs.Count
Write-Host "Total APKS: " -NoNewline; Write-Host $Count -ForegroundColor Yellow
ForEach ($APK in $APKs) {
    Write-Host ($Count.ToString() + "/" + $Counter.ToString()) -ForegroundColor Cyan -NoNewline; Write-Host " - Moving " -NoNewline; Write-Host $APK.FullName -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
    Move-Item -Path $APK.FullName -Destination "D:\Downloads\Android APK Applications" -Force -ErrorAction Continue
    Write-Host "Complete" -ForegroundColor Green
    $Counter ++
}