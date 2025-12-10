#Param ([IPAddress] $IP)
$IP = "10.10.231.221"
$ConnectionTest = $false
$DNSTest = $false

Write-Host "Pinging $IP - " -NoNewline
Try { Test-Connection $IP -ErrorAction Stop; $ConnectionTest = $true } Catch { $ConnectionTest = $false }
Write-Host "Resolving $IP in DNS - " -NoNewline
Try { Resolve-DnsName $IP -ErrorAction Stop; $DNSTest = $true }        Catch { $DNSTest = $false }
Write-Host "Complete"

If ($ConnectionTest -eq $false) { Write-Host "$IP is not pingable" -ForegroundColor Green } Else { Write-Host "$IP is pingable" -ForegroundColor Yellow }
If ($DNSTest -eq $false)        { Write-Host "$IP is not in DNS" -ForegroundColor Green }   Else { Write-Host "$IP is in DNS" -ForegroundColor Yellow }
