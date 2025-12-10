Param (
    [Parameter(Mandatory=$True, Position=1)]
    [DateTime] $Date
)

Function Start-Beep {
    For ($i = 0; $i -lt 3; $i++) {
        [Console]::Beep()
    }
}

If ($Date -lt (Get-Date)) {
    Write-Host "Date already passed"
    Break
}

$colors = [System.Enum]::GetValues([System.ConsoleColor]) | Where-Object { $_ -ne [System.ConsoleColor]::Black }

While ((Get-Date) -le $Date) {
    Clear-Host
    $remainingTime = ($Date - (Get-Date)) -f "HH:mm:ss"
    $randomColor = $colors | Get-Random
    [Console]::ForegroundColor = $randomColor
    Write-Host $remainingTime
    Start-Sleep -Seconds 1
}

Start-Beep
Start-Sleep -Seconds 2
Start-Beep

[Console]::ResetColor()