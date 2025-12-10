Param(
    [Parameter(Mandatory=$true,Position=1)]
    [String] $VMName, `
    [Parameter(Mandatory=$true,Position=2)]
    [String] $VMHost)

Clear-Host
#region Common Functions
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

Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Switch ($EndLine){
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
}

#endregion

Function Get-VMID{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $VMHost)

    Try{
        Write-Color -Text "Obtaining details for ", $VMName, " on ", $VMHost, " - " -Color White, Cyan, White, Cyan, White
            $Details = Get-VM -Name $VMName -ComputerName $VMHost | select Name, ID
        Write-Host "Complete" -ForegroundColor Green
        Return $Details
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Color -Text "Please confirm that ", $VMName, " exists on ", $VMHost -Color White, Yellow, White, Yellow -EndLine $true
        Return $null
    }
}

Get-VMID -VMName $VMName -VMHost $VMHost