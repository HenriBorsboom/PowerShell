#region Default Startup
Clear-Host
#region Common Functions
Function Debug{
    Param([Parameter(Mandatory=$false,Position=1)]
    $Variable)
    
    If ($Variable -eq $null)
    {
        $VariableDetails = "Empty Variable"
    }
    Else
    {
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
    If ($Return.ToLower() -eq "c")
    {
        Return
    }
    Else
    {
        Exit 1
    }
}

Function Strip-Name{
    Param([String] $Name)

    [String] $NewName = $item
    $NewName = $NewName.Remove(0, 7)
    $NewName = $NewName.Remove($NewName.Length - 1, 1)

    Return $NewName
}

Function Write-Color([String[]]$Text, [ConsoleColor[]]$Color) {
    for ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Write-Host
    #Write-Color -Text "Reading data from ","host1", " - ","complete" -Color White,Cyan,White,Green
}
#endregion
#endregion

Function Remove-Variables{
    Remove-Variable VMMServer
    Remove-Variable UserRole
    Remove-Variable User
    Remove-Variable OwnerUserRoleObj
    Remove-Variable VMNetwork
}

Function Test{
	[Console]::SetCursorPosition(1, 1)
	[Console]::Write('Hello')
}


#Remove-Variables
Test