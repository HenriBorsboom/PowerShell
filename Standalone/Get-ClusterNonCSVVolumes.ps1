$Cluster = "NRAZUREDBSC101"
$Results = Get-WmiObject -Query "select Caption,Size,Freespace from Win32_LogicalDisk" -ComputerName $Cluster
$Drives = @()
ForEach ($Drive in $Results) {
    $DriveDetails = $Drive.Caption + ";" + $Drive.Caption + ";" + ([Math]::Round($Drive.Size/1024/1024/1024)) + ";" + ([Math]::Round($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.Size/1024/1024/1024)-($Drive.FreeSpace/1024/1024/1024)) + ";" + [Math]::Round(($Drive.Freespace / $Drive.Size * 100))
    $Drives = $Drives + $DriveDetails
}
$Drives