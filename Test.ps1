Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    Write-Host "                                                                                                                                                                "
    [Console]::SetCursorPosition($x,$y)
}

Write-Host "Line 1"
Sleep 1
Delete-LastLine
Write-Host "Line 2"
Sleep 1
Delete-LastLine
Write-Host "Line 3"
