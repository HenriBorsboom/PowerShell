Param (
    [Parameter(Mandatory=$True, Position=1)][ValidateSet("Start","Stop")]
    [String] $Action)

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Set-Wuauserv {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Start","Stop")]
        [String] $Action)

    Switch ($Action) {
        "Start" {
            Write-Color -Text 'Getting state of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                $WUAUService = Get-Service wuauserv
            Write-Color -Text $WUAUService.Status -ForegroundColor Green
            If ($WUAUService.Status -eq 'Stopped') {
                Write-Color -Text 'Getting Startype of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                If ($WUAUService.StartType -eq 'Stopped') {
                    Write-Color -Text 'Setting StartType to ', 'Automatic', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                    Set-Service Wuauserv -StartupType Automatic
                }
                Else {
                    Write-Color -Text $WUAUService.StartType -ForegroundColor Green
                }
            }
            Write-Color -Text 'Starting ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                Start-Service wuauserv -ErrorAction stop -WarningAction SilentlyContinue
            Write-Color -Text 'Complete' -ForegroundColor Green
            Write-Color -Text 'State of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
            Write-Color -Text (Get-Service wuauserv).Status -ForegroundColor Green
            Write-Color -Text 'Starting ', 'Windows Update Control Panel Applet', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
            Invoke-Expression 'Control /Name Microsoft.WindowsUpdate'
            Write-Color -Text 'Complete' -ForegroundColor Green
        }
        "Stop"  {
            Write-Color -Text 'Getting state of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                $WUAUService = Get-Service wuauserv
            Write-Color -Text $WUAUService.Status -ForegroundColor Green
            If ($WUAUService.Status -eq 'Running') {
                Write-Color -Text 'Getting Startype of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                If ($WUAUService.StartType -eq 'Automatic') {
                    Write-Color -Text 'Setting StartType to ', 'Disabled', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                    Set-Service Wuauserv -StartupType Disabled
                }
                Else {
                    Write-Color -Text $WUAUService.StartType -ForegroundColor Green
                }
            }
            Write-Color -Text 'Stopping ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
                Stop-Service wuauserv -ErrorAction stop -WarningAction SilentlyContinue
            Write-Color -Text 'Complete' -ForegroundColor Green
            Write-Color -Text 'State of ', 'Windows Update Services', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
            Write-Color -Text (Get-Service wuauserv).Status -ForegroundColor Green
        }
    }
}

Set-Wuauserv -Action $Action