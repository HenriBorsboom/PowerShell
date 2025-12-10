$Source = 'D:'
$VHDs = Get-ChildItem -Path $Source -Include *.vhd* -Recurse

$VHDDetails = @()
For ($VHDi = 0; $VHDi -lt $VHDs.Count; $VHDi ++) {
    $VHDDetails += ,(Get-VHD -Path $VHDs[$VHDi].FullName)
}
$VHDDetails | Format-Table -AutoSize
Write-Host ("Total File Size: " + [Math]::Round(($VHDDetails | Measure-Object -Sum -Property FileSize).Sum / 1024 / 1024 / 1024, 2).ToString() + ' GB')
Write-Host ("Total Size: " + [Math]::Round(($VHDDetails | Measure-Object -Sum -Property Size).Sum / 1024 / 1024 / 1024, 2) + ' GB')

(Get-WmiObject -Query "Select * from Win32_LogicalDisk where DeviceID = '$Source'") | Select-Object { $_.DeviceID, ([Math]::Round($_.FreeSpace/1024/1024/1024, 2)), ([Math]::Round($_.Size/1024/1024/1024, 2)) }