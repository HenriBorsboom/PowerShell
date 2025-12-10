Function Write-Color {
    Param(
        [Parameter(Mandatory=$False, Position = 1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position = 3)]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position = 4)]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position = 5)]
        [Switch] $Complete, `
        [Parameter(Mandatory=$False, Position = 6)]
        [Switch] $SendToLog)

    $CurrentActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    If ($Text.Count -gt 0) {
        If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
        ElseIf ($BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'ResetBackground' }
        ElseIf ($ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -eq 0) { $OperationMode = 'ResetForeground' }
        ElseIf ($BackgroundColor.Count -ge $Text.Count -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0) { $OperationMode = 'ResetForegroundWithBackground' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0) { $OperationMode = 'ResetBackgroundWithForeground' }
        ElseIf ($BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0) { $OperationMode = 'ResetColors' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -ge $Text.Count) { $OperationMode = 'Normal' }
        ElseIf ($BackgroundColor.Count -ge $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
        ElseIf ($ForegroundColor.Count -ge $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
        Else { 
            Write-Host "Text Count: " $Text.Count
            Write-Host "Foreground Count: " $ForegroundColor.Count
            Write-Host "Background Count: " $BackgroundColor.Count
        }
    }
    ElseIf ($Complete -eq $True) {
        $OperationMode = 'Complete'
    }

    Switch ($OperationMode) {
        'Foreground' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
            }
        }
        'Background' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine
            }
        }
        'WriteHost' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -NoNewLine
            }
        }
        'ResetForeground' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
            }
        }
        'ResetBackground' {
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetForegroundWithBackground' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetBackgroundWithForeground' {
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'ResetColors' {
            For ($ForegroundColorIndex = ($ForegroundColor.Count); $ForegroundColorIndex -lt $Text.Count; $ForegroundColorIndex++) {
                    $ForegroundColor += ,($ForegroundColor[0])
            }
            For ($BackgroundColorIndex = ($BackgroundColor.Count); $BackgroundColorIndex -lt $Text.Count; $BackgroundColorIndex++) {
                    $BackgroundColor += ,($BackgroundColor[0])
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        'Complete' {
            Write-Host "Complete" -ForegroundColor Green
        }
        'Normal' {
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -Background $BackgroundColor[$Index] -NoNewLine
            }
        }
        Default {
            Write-Host ("Unknown Issue: ")
            Write-Host ("Text Count: " + $Text.Count.ToString()) -NoNewline
            Write-Host ("Foreground Count: " + $ForegroundColor.Count.ToString()) -NoNewline
            Write-Host ("Background Count: " + $BackgroundColor.Count.ToString()) -NoNewline
            Throw
        }
    }
    If ($SendToLog -eq $True) { Write-Log -LogData @("Write-Color", "SendToLog Switch", $Text, $ForegroundColor.Count, $BackgroundColor.Count) }
    If ($NoNewLine -eq $False) { Write-Host }
    $ErrorActionPreference = $CurrentActionPreference
}
Function Write-Log {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $LogData, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $FilePath)

    If ($Global:LogFile -eq "") { $FilePath = $env:TEMP + "\log.txt" }
    Else { $FilePath = $Global:LogFile }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - Start ---------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
    ForEach ($Data in $LogData) { $Data | Out-File $FilePath -Encoding ascii -Append }
    (("[" + '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date) + "]") + " - End -----------------------------------------------------") | Out-File $FilePath -Encoding ascii -Append
}
Function Call-Log {
    If ($Global:LogFile -eq "") { $FilePath = ($env:TEMP + "\log.txt") }
    Else { $FilePath = $Global:LogFile }
    notepad $FilePath
}
Function Clear-Log {
    If ($Global:LogFile -eq "") { $FilePath = ($env:TEMP + "\log.txt") }
    Else { $FilePath = $Global:LogFile }
    If (Test-Path $FilePath) { Remove-Item $FilePath }
}
$Global:LogFile = 'C:\Temp\SandboxLog.txt'

#Test
Clear-Host
Write-Color -Text "Test 1"
Write-Color -Text "Test 1" -ForegroundColor Yellow
Write-Color -Text "Test 1" -BackgroundColor Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow
Write-Color -Text "Test 1", "Test 2" -BackgroundColor Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow -BackgroundColor Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow, Yellow -BackgroundColor Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow -BackgroundColor Black, Black

Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow, Yellow, Yellow -BackgroundColor Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow -BackgroundColor Black, Black, Black
Write-Color -Text "Test 1", "Test 2" -ForegroundColor Yellow, Yellow, Yellow
Write-Color -Text "Test 1", "Test 2" -BackgroundColor Black, Black, Black

