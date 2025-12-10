$Colors = @()
$Colors += ('Black')
$Colors += ('DarkBlue')
$Colors += ('DarkGreen')
$Colors += ('DarkCyan')
$Colors += ('DarkRed')
$Colors += ('DarkMagenta')
$Colors += ('DarkYellow')
$Colors += ('Gray')
$Colors += ('DarkGray')
$Colors += ('Blue')
$Colors += ('Green')
$Colors += ('Cyan')
$Colors += ('Red')
$Colors += ('Magenta')
$Colors += ('Yellow')
$Colors += ('White')

For ($Bi = 0; $Bi -lt $Colors.Count; $Bi ++) {
    For ($Fi = 0; $Fi -lt $Colors.Count; $Fi ++) {
        Write-Host ("Background: " + $Colors[$Bi]) -BackgroundColor $Colors[$Bi] -ForegroundColor $Colors[$Fi] -NoNewline
        Write-Host " " -NoNewline
        Write-Host ("Foreground:" + $Colors[$Fi]) -BackgroundColor $Colors[$Bi] -ForegroundColor $Colors[$Fi]
    }
}