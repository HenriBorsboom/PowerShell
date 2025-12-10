$Servers = @(
"WEBSERVER101", `
"WEBSERVER102", `
"WEBSERVER103", `
"WEBSERVER104", `
"WEBSERVER105", `
"WEBSERVER106", `
"WEBSERVER107", `
"WEBSERVER108", `
"WEBSERVER108", `
"NRAZUREAPP105", `
"NRAZUREAPP106", `
"NRAZUREAPP107", `
"NRAZUREAPP108", `
"NRAZUREAPP109", `
"NRAZUREAPP110", `
"NRAZUREAPP111")

ForEach ($Server in $Servers) {
$WMIRAM = Get-WmiObject -Query "select * from win32_logicaldisk" -ComputerName $Server

#$Total = $WMIRAM.TotalPhysicalMemory
#$Total = $Total / 1024 /1024 /1024
#$TotalGB = [System.Math]::Round($Total,2)
    ForEach ($Drive in $WMIRAM) {
        Write-Host $Server ' - ' $Drive.DeviceID ' - ' $Drive.Size ' - ' $Drive.FreeSpace 
    }
}