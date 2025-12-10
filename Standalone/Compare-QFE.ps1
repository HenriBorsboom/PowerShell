Clear-Host
$APP101QFE = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName APPSERVER101
$APP201QFE = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName NRAZUREAPP201

$APP101QFE = $APP101QFE.HotFixID
$APP201QFE = $APP201QFE.HotFixID

Write-Host "APPSERVER101 QFE Count: " $APP101QFE.count
Write-Host "NRAZUREAPP201 QFE Count: " $APP201QFE.count

$APP101QFEMissing = @()
$APP201QFEMissing = @()

ForEach ($HotFix in $APP201QFE) {
    If ($APP201QFE.Contains($Hotfix)) { }
    Else { Write-Host "APPSERVER101 is missing: " $HotFix.HotFixID; $APP101QFEMissing = $APP101QFEMissing + $HotFix }
}

ForEach ($HotFix in $APP101QFE) {
    If ($APP101QFE.Contains($Hotfix)) { }
    Else { Write-Host "NRAZUREAPP201 is missing: " $HotFix.HotFixID; $APP201QFEMissing = $APP201QFEMissing + $HotFix }
}

Write-Host "APPSERVER101 Missing Hotfix Count: " $APP101QFEMissing
Write-Host "NRAZUREAPP201 Missing Hotfix Count: " $APP201QFEMissing