# Notes:
# Removed sentive information in strings and replaced with '<common descriptive info>'
# Replace the '' and the information inside with environment information

#region Common Functions
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Bool]           $EndLine)
    Begin {
    }
    Process {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($EndLine){
            $True  { Write-Host            }
            $False { Write-Host -NoNewline }
        }
    }
}

Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}
#endregion
