Clear-Host

$Servers = @("APPSERVER101", `
"NRAZUREAPP102", `
"APPSERVER103", `
"NRAZUREAPP104", `
"NRAZUREAPP105", `
"NRAZUREAPP106", `
"NRAZUREAPP107", `
"NRAZUREAPP108", `
"NRAZUREAPP109", `
"NRAZUREAPP110", `
"NRAZUREAPP111", `
"NRAZUREAPP112", `
"NRAZUREAPP201", `
"NRAZUREAPP202", `
"NRAZUREAPP203", `
"NRAZUREAPP204", `
"NRAZUREAPP205", `
"NRAZUREAPP207", `
"NRAZUREAPP208", `
"NRAZUREAPP209", `
"NRAZUREAPP210", `
"NRAZUREAPP211", `
"NRAZUREAPP212", `
"NRAZUREAPP213", `
"NRAZUREAPP214", `
"NRAZUREAVI201", `
"NRAZUREDBS101", `
"NRAZUREDBS201", `
"NRAZUREFLS201", `
"NRAZUREGCS101", `
"NRAZUREGCS102", `
"VMSERVER201", `
"NRAZUREGCS202", `
"NRAZURESQL101", `
"NRAZURESQM101", `
"TSSERVER201", `
"WEBSERVER101", `
"WEBSERVER102", `
"WEBSERVER103", `
"WEBSERVER104", `
"WEBSERVER105", `
"WEBSERVER106", `
"WEBSERVER107", `
"WEBSERVER108", `
"NRAZUREVMH101", `
"NRAZUREVMH102", `
"NRAZUREVMH103", `
"NRAZUREVMH201", `
"NRAZUREVMH202")

Function Get-OS {
    Param(
        [Array] $Computers)
        $Out = New-Object PSObject

    Write-Host "Total Servers: " $Computers.Count
    $x = 1
    ForEach ($Server in $Computers) {
        #Write-Host "$x/"$Computers.Count" - $Server"
        $Results = Get-WmiObject -Query "Select Name from Win32_Product" -ComputerName $Server
        
        $Products = $Results.Name
        ForEach ($item in $Products) {
            Write-Host "$x - $Server - $item"
        }
        $x ++
    }
}

Get-OS -Computers $Servers