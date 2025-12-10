$target = "labadexternal.ansible.local"
$cred = Get-Credential -Message "Enter domain credentials for CredSSP test"

Write-Host "`n➡️ Testing basic WinRM connectivity to $target..." -ForegroundColor Cyan
try {
    Test-WSMan -ComputerName $target -Authentication Default
    Write-Host "✅ WinRM reachable" -ForegroundColor Green
} catch {
    Write-Host "❌ WinRM not reachable: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n➡️ Testing PowerShell Remoting with CredSSP..." -ForegroundColor Cyan
try {
    $session = New-PSSession -ComputerName $target -Authentication Credssp -Credential $cred
    Invoke-Command -Session $session -ScriptBlock { whoami; hostname }
    Remove-PSSession $session
    Write-Host "✅ CredSSP logon successful" -ForegroundColor Green
} catch {
    Write-Host "❌ CredSSP failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n➡️ Attempting fallback with Kerberos..." -ForegroundColor Cyan
try {
    $session = New-PSSession -ComputerName $target -Authentication Kerberos -Credential $cred
    Invoke-Command -Session $session -ScriptBlock { whoami; hostname }
    Remove-PSSession $session
    Write-Host "✅ Kerberos logon successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Kerberos failed: $($_.Exception.Message)" -ForegroundColor Yellow
}
