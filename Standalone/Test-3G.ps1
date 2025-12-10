Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory=$true,Position=2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}


$SuccessCount = 0
$ContinuesSuccess = 0
$FailCount = 0
$StartTime = Get-Date
for ($x = 1; $x -lt 10000; $x ++) {
    $CurrentTime = Get-Date
    $Duration = Get-TotalTime -StartTime $StartTime -EndTime $CurrentTime
    Clear-Host
    Write-Host "Connection Successfull:  " -NoNewline; Write-Host $SuccessCount -ForegroundColor Green
    Write-Host "Continues Success Count: " -NoNewline; Write-Host $ContinuesSuccess -ForegroundColor Yellow
    Write-Host "Missed Pings:            " -NoNewline; Write-Host $FailCount -ForegroundColor Red
    Write-Host ""
    Write-Host "Start Time:              " -NoNewline; Write-Host $StartTime.ToLongTimeString() -ForegroundColor Cyan
    Write-Host "Current Time:            " -NoNewline; Write-Host $CurrentTime.ToLongTimeString() -ForegroundColor Cyan
    Write-Host "Duration:                " -NoNewline; Write-Host $Duration -ForegroundColor Cyan
    

    Try {
        $empty = Test-Connection -ComputerName www.google.co.za -ErrorAction stop
        $SuccessCount ++
        $ContinuesSuccess ++
        
        If ($ContinuesSuccess -gt 5) {
            $FailCount = 0
            $ContinuesSuccess = 0
        }
    }
    Catch {
        $FailCount ++
        If ($FailCount -eq 5) {
            [console]::beep(500,300)
            [console]::beep(500,300)
            [console]::beep(500,300)
            [console]::beep(500,300)
            $FailCount = 0
        }
    }
    Sleep 2
}
[console]::beep(500,300)