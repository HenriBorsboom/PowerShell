Function Update-Progress {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int16] $Seconds)

    If ($Host.Name -notlike '*ISE*') {
        $CursorLeft = [Console]::CursorLeft
        $CursorTop  = [Console]::CursorTop
    
        $CursorIndex = @('-', '\', '|', '/')
        $CurrentSpot = $null
        For ($SecondCount = 0; $SecondCount -lt $Seconds; $SecondCount ++) {
            For ($MillisecondCount = 0; $MillisecondCount -lt 10; $MillisecondCount ++) {
                If ($CurrentSpot -eq $null)              { $CurrentSpot = 0 }
                If ($CurrentSpot -gt $CursorIndex.Count) { $CurrentSpot = 0 }
                Write-Host $CursorIndex[$CurrentSpot] -NoNewline -ForegroundColor Cyan
                $CurrentSpot ++
                [Console]::SetCursorPosition($CursorLeft, $CursorTop)
                Start-Sleep -Milliseconds 100
            }
        }
        Write-Host "Complete" -ForegroundColor Green
    }
    Else {
        For ($SecondCount = 0; $SecondCount -lt $Seconds; $SecondCount ++) {
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds 1
        }
    }
}


Update-Progress -Seconds 3