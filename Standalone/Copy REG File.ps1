#  copy .\servers2.reg \\10.12.11.98\c$\windows
For ($IP = 2; $IP -lt 240; $IP ++) {
    Try {
        $Server = "10.12.11." + $IP.ToString()
        Write-Host "Copying to " -NoNewline
        Write-Host $Server -NoNewline -ForegroundColor Yellow
        Write-Host " - " -NoNewline
            Copy .\servers2.reg \\$Server\c$\windows
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        #Break
    }
}