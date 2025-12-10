Clear-Host

$Server = "SYSJHBFS"
$TimeFormat = '{0:dd-MM-yyyy HH:mm:ss}'
$CounterFormat = '{0:D3}'
$Counter = 1
While ($True) {
    Try { 
        $Date = (Get-Date).ToShortTimeString()
        Write-Host (($CounterFormat -f $Counter).ToString() + " - " + "Testing $Server - ") -NoNewline
        $Result = Get-WmiObject -Class Win32_OperatingSystem -Property Caption -ComputerName $Server -ErrorAction Stop
        Write-Host ("Success - " + ($TimeFormat -f $Date) + " ") -ForegroundColor Green -NoNewline
        Write-Host "Sleeping 10 seconds" -ForegroundColor DarkCyan
        Sleep 10
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
    }
}