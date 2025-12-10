$Servers = @(
'NRAZUREVMH101', `
'NRAZUREVMH102', `
'NRAZUREVMH103', `
'NRAZUREVMH201', `
'NRAZUREVMH202')

ForEach ($Server in $Servers) {
$WMIRAM = Get-WmiObject -Query 'select totalphysicalmemory from win32_computersystem' -ComputerName $Server

$Total = $WMIRAM.TotalPhysicalMemory
$Total = $Total / 1024 /1024 /1024
$TotalGB = [System.Math]::Round($Total,2)
Write-Host $Server ' - ' $TotalGB 'GB' 
}