Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}

Clear-Host

$Server        = "SYSJHBFS"
$TimeFormat    = '{0:HH:mm:ss}'
$CounterFormat = '{0:D3}'
$Counter       = 1
While ($True) {
    Try { 
        Write-Host (($CounterFormat -f $Counter).ToString() + " - " + "Testing $Server - ") -NoNewline
        $StartTime = Get-Date
        $Result = Get-WmiObject -Class Win32_OperatingSystem -Property Caption -ComputerName $Server -ErrorAction Stop
        $EndTime = Get-Date
        $Date = ($TimeFormat -f $EndTime)
        $Duration = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
        Write-Host ("Success - " + $Date + " " + "[" + $Duration + "]" + " - ") -ForegroundColor Green -NoNewline
        Write-Host "Sleeping 10 seconds" -ForegroundColor DarkCyan
        Sleep 10
        $Counter ++
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
    }
}