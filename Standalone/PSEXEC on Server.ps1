#psexec \\10.12.11.98 -u administrator -p P@ssw0rd netsh advfirewall set allprofiles state off
# REG IMPORT AppBkUp.reg

For ($IP = 2; $IP -lt 103; $IP ++) {
    Try {
        $Server = "10.12.11." + $IP.ToString()
        $Command = 'PSEXEC \\' + $Server + ' -u administrator -p P@ssw0rd REG IMPORT c:\windows\servers2.reg'
        Write-Host "Imporing Registry " -NoNewline
        Write-Host $Server -NoNewline -ForegroundColor Yellow
        Write-Host " - " -NoNewline
            $Empty = Invoke-Expression $Command
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
    }
}