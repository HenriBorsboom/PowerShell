Function UpdateLine {
    Param ($int)
    
    For ($i = 1; $i -lt ($int + 1); $i ++) {
        Write-Host "." -NoNewline
        Sleep 1
    }
    Write-Host " " -NoNewLine
}
Function MSFDB {
    Param ([Bool] $Start)
    Switch ($Start) {
        $True  { 
            Write-Host "Starting MSF Database - " -NoNewline
                $MSFDB = Start-Job -ScriptBlock { Invoke-Expression "C:\metasploit-framework\bin\msfdb.bat start" }
                While ($MSFDB.State -eq "running") { Write-Host "." -NoNewline; sleep 1 }
                Remove-Job $MSFDB
            Write-Host " - Complete" -ForegroundColor Green
        }
        $False {
            Write-Host "Stopping MSF Database - " -NoNewline
                $MSFDB = Start-Job -ScriptBlock { Invoke-Expression "C:\metasploit-framework\bin\msfdb.bat stop" }
                While ($MSFDB.State -eq "running") { Write-Host "." -NoNewline; sleep 1 }
                Remove-Job $MSFDB
            Write-Host " - Complete" -ForegroundColor Green
        }
    }
}
Function StartMSF {
    Write-Host "Starting MSF RPC Daemon - " -NoNewline
        $MSFRPCD = Start-Job -ScriptBlock { Invoke-Expression "C:\metasploit-framework\bin\startdeamon.cmd" }
        UpdateLine 7
    Write-Host "Complete" -ForegroundColor Green
    MSFDB -Start:$true
}
Function StopMSF{
    MSFDB -Start:$False
    Write-Host "Stopping MSF RPC Daemon - " -NoNewline
        Get-Job | Stop-Job
        Get-Job | Remove-Job
    Write-Host "Complete" -ForegroundColor Green
}

Clear-Host
StartMSF
Write-Host "Starting MSF Console - " -NoNewline
    Start-Process -FilePath "C:\metasploit-framework\bin\msfconsole.bat" -WindowStyle Maximized -Wait -verb runAs
Write-Host "Complete" -ForegroundColor Green
StopMSF