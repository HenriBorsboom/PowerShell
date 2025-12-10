Write-Host "Flushing DNS - " -NoNewline
    Try { 
        Invoke-expression "ipconfig /flushdns" -ErrorAction Stop | Out-Null
        Write-Host "Complete" -ForegroundColor Green 
    } 
    Catch { 
        Write-Host "Failed" -ForegroundColor Red 
    }

Write-Host "Releasing and Refresh WINS - " -NoNewline
    Try { 
        Invoke-expression "nbtstat -RR" -ErrorAction Stop | Out-Null 
        Write-Host "Complete" -ForegroundColor Green 
    } 
    Catch { 
        Write-Host "Failed" -ForegroundColor Red 
    }

Write-Host "Purge and reload NetBIOS - " -NoNewline
    Try { 
        Invoke-expression "nbtstat -R" -ErrorAction Stop | Out-Null
        Write-Host "Complete" -ForegroundColor Green 
    } 
    Catch { 
        Write-Host "Failed" -ForegroundColor Red 
    }

Write-Host "Registering DNS - " -NoNewline
    Try { 
        Invoke-expression "ipconfig /registerdns" | Out-Null -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green 
    } 
    Catch { 
        Write-Host "Failed" -ForegroundColor Red 
    }