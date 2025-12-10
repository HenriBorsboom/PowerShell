#region Common Functions
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
Function Process-Error {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $CaughtError)

    $ErrorMessages = (($CaughtError.Exception.GetBaseException()).ToString() -split ": ")
    Return $ErrorMessages[1]
}
#endregion

Function Start-Services {
    $AllServices         = Get-WmiObject -Class Win32_Service 
    For ($i = 0; $i -lt $AllServices.Count; $i ++) {
        Try {
            Write-Color -Text "Checking if ", $AllServices[$i].DisplayName, " needs to be start - " -ForegroundColor White, Yellow, White -NoNewLine
            If ($AllServices[$i].StartMode -eq "Auto" -and $AllServices[$i].State -ne "Running") {
                Write-Color -Text "Starting", " - " -ForegroundColor Yellow, White -NoNewLine
                    Start-Service -name $AllServices[$i].Name
                Write-Color -Text "Complete" -ForegroundColor Green
            }
            Else {
                Write-Color "Skipping" -ForegroundColor Green
            }
        }
        Catch {
            Write-Color -Text (Process-Error $_) -ForegroundColor Red
        }
    }
}
Clear-Host
Start-Services