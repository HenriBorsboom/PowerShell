Function GetDomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Enabled -eq $true -and Name -like "NRAZURE*"}
    $Servers | Sort Name

    Return $Servers    
}
Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}
Write-Host "Getting computers from Active Directory - " -NoNewline
$Servers = GetDomainComputers
Write-Host "Complete" -ForegroundColor Green
$Counter = 1
$Count = $Servers.Count
Write-Host "Total Servers: $Count"
ForEach ($Server in $Servers.Name) {
    Write-Host "$Counter/$Count - Getting Applications on $Server - "-NoNewline
    $Results = Get-WmiObject -ComputerName $Server -Query "Select Caption from Win32_Product"
    Write-Host "Complete" -ForegroundColor Green -NoNewline
    Write-Host " - exporting applications to text file - " -NoNewline
    ForEach ($Application in $Results.Caption) {
        $Output = $Server + ";" + $Application
        $Output | Out-File C:\Temp\Applications.txt -Encoding ascii -Append -NoClobber -Force
    }
    Write-Host "Complete" -ForegroundColor Green
    Delete-LastLine
    $Counter ++
}
