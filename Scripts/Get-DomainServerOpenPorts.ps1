Import-Module ActiveDirectory

$Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Name -like "NRAZURE*"}

$Count = $Servers.Count
$x = 1
Write-Host "Total Servers: $Count" 
ForEach ($Server in $Servers.Name) {
    Try {
        Write-Host "$x/$Count" -ForegroundColor Yellow -NoNewline
        Write-Host " - " -NoNewline
        Write-Host "Obtaining Listing ports on " -NoNewLine
        Write-Host "$Server" -ForegroundColor Cyan -NoNewline
        Write-Host " - " -NoNewline
        $Ports = Invoke-Command -ComputerName $Server -ScriptBlock {Get-NetTCPConnection -LocalAddress 0.0.0.0 -State Listen}
        Write-Host "Complete" -ForegroundColor Green
        $Ports | Out-File "c:\temp\Ports - $Server.txt" -Encoding ascii -Append -NoClobber
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
