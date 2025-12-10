Clear-Host

Function Delete-LastLine {    $x = [Console]::CursorLeft    $y = [Console]::CursorTop    [Console]::SetCursorPosition($x,$y - 1)    Write-Host "                                                                                                                                            "    [Console]::SetCursorPosition($x,$y - 1)}

For ($x = 1; $x -lt 100000; $x ++) {
    Write-Host (Get-Date).ToLongTimeString() -ForegroundColor Cyan -NoNewline
    Write-Host " - " -NoNewline
    $Collection = (Get-ChildItem C:\WSUS -Recurse | Measure-Object -Property Length -Sum)
    $WSUSSize = "{0:N2}" -f ($Collection.Sum / 1MB) + " MB"
    Write-Host "$WSUSSize" -ForegroundColor Yellow
    For ($Delay = 1; $Delay -lt 60; $Delay ++) {
        Write-Host "|-- Waiting " -NoNewLine
        Write-Host $Delay -ForegroundColor Red -NoNewline
        Write-Host "/60 Seconds -- "
        Sleep 1
        Delete-LastLine
    }
}