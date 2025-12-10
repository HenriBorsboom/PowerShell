Function Spot-Update {
    Param ([Parameter(Mandatory = $True)] [Int64] $Counter)
    $TimeSpan =  [TimeSpan]::FromSeconds($Counter)
    $Timer = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    $CursorLeft = [Console]::CursorLeft
    $CursorTop  = [Console]::CursorTop
        
    [Console]::SetCursorPosition($CursorLeft,$CursorTop)
    Write-Host $Timer
    [Console]::SetCursorPosition($CursorLeft,$CursorTop)
}
Clear-Host
Write-Host "test 1 - " -NoNewline
For ($x = 0; $x -lt 3; $x ++) {
    Spot-Update -Counter $x
    sleep 1
}
Write-Host "Complete"