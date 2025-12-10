Clear-Host
$Servers = @(
    "SYSCTSTORE", 
    "SYSCTDC", 
    "SYSJHBFS")

Write-Host ("Running on: " + $env:COMPUTERNAME) -ForegroundColor Yellow
ForEach ($Server in $Servers) {
    Try {
        Write-Host ("Connecting to " + $Server + " - ") -ForegroundColor White -NoNewline
        $Result = Get-WmiObject -Class Win32_OperatingSystem -Property LastBootUpTime -ComputerName $Server -ErrorAction Stop
        Write-Host ("Success - " + $Result.LastBootUpTime)
    }
    Catch {
        Write-Host ("Failed - " + $_) -ForegroundColor Red
    }
}