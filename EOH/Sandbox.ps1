Function Write-Menu {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Menu, `
        [Parameter(Mandatory=$True, Position=4)]
        [ConsoleColor] $Foreground, `
        [Parameter(Mandatory=$True, Position=5)]
        [ConsoleColor] $Background, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int16] $Line, `
        [Parameter(Mandatory=$True, Position=3)]
        [Int16] $LastCursorPosition)
    
    Clear-Host
    [Console]::SetCursorPosition(0, 24)
    Write-Host "Line: $Line"
    [Console]::SetCursorPosition(0, 25)
    Write-Host "Position: $LastCursorPosition"
    [Console]::SetCursorPosition(0, 0)
    For ($LineIndex = 0; $LineIndex -lt $MyMenu.Count; $LineIndex ++) {
        If ($LineIndex -eq $Line) {
            Write-Host $Menu[$LineIndex] -ForegroundColor $BackgroundColor -BackgroundColor $ForegroundColor
        }
        Else {
            Write-Host $Menu[$LineIndex] -ForegroundColor $Foreground -BackgroundColor $BackgroundColor
        }
    }
    If ($Line -eq -1) { Write-Host "Error" }
    If ($Line -ge 0) {
        [Console]::SetCursorPosition($LastCursorPosition, $Line)
    }
}
, 
[ConsoleColor] $Foregroundcolor = 'White'
[ConsoleColor] $Backgroundcolor = 'Black'

[String[] ] $MyMenuSimple = @()
$MyMenu += ,("..........................................................")
$MyMenu += ,("                        Menu                              ")
$MyMenu += ,("..........................................................")
$MyMenu += ,("01 .......................................................")
$MyMenu += ,("02 .......................................................")
$MyMenu += ,("03 .......................................................")
$MyMenu += ,("04 .......................................................")
$MyMenu += ,("05 .......................................................")
$MyMenu += ,("06 .......................................................")
$MyMenu += ,("07 .......................................................")
$MyMenu += ,("08 .......................................................")
$MyMenu += ,("09 .......................................................")
$MyMenu += ,("10 .......................................................")

If ($Host.Name -notlike '*ISE*') {
    Write-Menu -Menu $MyMenu -Foreground $Foregroundcolor -Background $Backgroundcolor -Line ($MyMenu.Count - 1) -LastCursorPosition ($MyMenu[-1].Length + 1)
    While ($true) {
        $UpDown = [Console]::CursorTop
        $KeyInfo = $Host.UI.RawUI.ReadKey()
        If ($KeyInfo.VirtualKeyCode -eq 38) {
            If ($UpDown -gt 3) {
                Write-Menu -Menu $MyMenu -Foreground $Foregroundcolor -Background $Backgroundcolor -Line ($UpDown - 1) -LastCursorPosition ($MyMenu[-1].Length + 1)
            }
            Else {
                Write-Menu -Menu $MyMenu -Foreground $Foregroundcolor -Background $Backgroundcolor -Line $UpDown -LastCursorPosition ($MyMenu[-1].Length + 1)
            }
        }
        ElseIf ($KeyInfo.VirtualKeyCode -eq 40) {
            If ($UpDown -ge 2 -and $UpDown -lt $MyMenu.Count - 1) {
                Write-Menu -Menu $MyMenu -Foreground $Foregroundcolor -Background $Backgroundcolor -Line ($UpDown + 1) -LastCursorPosition ($MyMenu[-1].Length + 1)
            }
            Else {
                Write-Menu -Menu $MyMenu -Foreground $Foregroundcolor -Background $Backgroundcolor -Line $UpDown -LastCursorPosition ($MyMenu[-1].Length + 1)
            }
        }
        ElseIf ($KeyInfo.VirtualKeyCode -eq 13) {
            [Console]::SetCursorPosition(($MyMenu[-1].Length + 1),$UpDown)
            Write-Host ("Menu Item Selected: " + ($UpDown + 1).ToString()) -NoNewline
        }
        Else {
            Start-Sleep -Milliseconds 100
        }
    }
}
Else {
    Start-Process powershell 'C:\Users\henri.borsboom\Documents\Scripts\PowerShell\EOH\sandbox.ps1'
}