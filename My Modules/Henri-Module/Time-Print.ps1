Clear-Host

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

$StartTime = Get-Date
Write-Host "Start time: " $StartTime.ToLongTimeString()
Sleep 2

$EndTime = Get-Date
Write-Host "End time: " $StartTime.ToLongTimeString()

$Duration = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
Write-Host $Duration