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