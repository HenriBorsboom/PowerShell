Function Debug{
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        $Variable)
    
    If ($Variable -eq $null){
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
    If ($Return.ToLower() -eq "c"){
        Return
    }
    Else{
        Exit 1
    }
}
Function Strip-Name{
    Param(
        [String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}
Function Get-DomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Enabled -eq $true -and Name -like "NRAZURE*"}
    $Servers | Sort Name

    Return $Servers    
}

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]         $Nonewline=$False)
    Begin {
    }
    Process {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($Nonewline){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$true,  Position=1)]
        [Object] $StartTime, `
        [Parameter(Mandatory=$false, Position=2)]
        [DateTime] $EndTime)
        
    Switch ($StartTime.GetType().name) {
        "DateTime" {
            If ( $EndTime -eq $null ) { $EndTime = Get-Date }
            $ReturnVariable = ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Start $StartTime -End $EndTime).TotalSeconds))
        }
        "int32" {
            $ReturnVariable = ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Seconds $StartTime).TotalSeconds))
        }
    }
    Return $ReturnVariable
}
Function Delete-LastLine {
    $PShost = Get-Host
    $pswindow = $pshost.ui.rawui

    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    $String = ""
    For ($i = 0; $i -lt $pswindow.windowsize.Width; $i ++) {
        $String = ($String + " ")
    }
    
    Write-Host $String 
    [Console]::SetCursorPosition($x,$y -1)
}
