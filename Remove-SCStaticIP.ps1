Param (
    [Parameter(Mandatory=$true,Position=1)]
    [String] $SCIP)

Function Remove-SCStaticIP {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $SCIP)

    Try {
        Write-Host "Obtaining supplied IP from SCVMM - " -NoNewline
            $IP = Get-SCIPAddress -IPAddress $SCIP -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
        
        Write-Host "Attempting to revoke IP - " -NoNewline
            $empty = Revoke-SCIPAddress -AllocatedIPAddress $IP -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    
        Write-Host "Confirming IP revoked - " -NoNewline
            Get-SCIPAddress | Where Name -Like "*$SCIP*" | Select Description,Name -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Break
    }
}

Remove-SCStaticIP -SCIP $SCIP