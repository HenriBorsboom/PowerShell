Function Delete-LastLine {
    Try {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
    }
    Catch {
    }
}

Clear-Host
For ($x = 1; $x -lt 10; $x ++) {
    If ($x -eq 1) {
        Write-Host "line 1"
    }
    If ($x -eq (1 + 1)) {
        Delete-LastLine
        Write-host "line 1"
        Write-Host "line 2"
    }
    If ($x -gt (2)) {
        Delete-LastLine
        Delete-LastLine
        Write-host "output $x"
        Write-host "output "
        
    }
    
    sleep 1   





}