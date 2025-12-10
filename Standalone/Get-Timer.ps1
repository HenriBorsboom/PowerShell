Function Get-Timer {
    Param(
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCount)

    $Duration = New-TimeSpan -Seconds($x)
    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
