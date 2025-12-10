# Coding Functions

Function Debug-Variable {
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        [Object] $Variable)
    
    If ($Variable -eq $null) {
        $VariableDetails = "Empty Variable"
    }
    Else{
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c") {
        Return
    }
    Else {
        Exit 1
    }
}

Function Strip-Name {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Name)

    [String] $NewName = $item
    $NewName = $NewName.Remove(0, 7)
    $NewName = $NewName.Remove($NewName.Length - 1, 1)

    Return $NewName
}

Function Write-Color {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String[]]$Text, `
        [Parameter(Mandatory=$true,Position=2)]
        [ConsoleColor[]]$Color, `
        [Parameter(Mandatory=$false,Position=3)]
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    
    Switch ($EndLine) {
        $true {
            Write-Host
        }
        $false {
            Write-Host -NoNewline
        }
    }
}
