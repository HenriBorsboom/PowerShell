# Verification Script - Check for remaining sensitive data
$SourcePath = "c:\Users\slash\OneDrive\Documents\PowerShell"

Write-Host "`nVerifying sanitization..." -ForegroundColor Cyan

# Check for passwords
Write-Host "`n1. Checking for passwords..." -ForegroundColor Yellow
$passwords = @('Trustnoone9877', 'Trustnoone8521', 'Trustnoone4566', 'Pr0xy@uth3nt1c@te', '@Tomic4321')
$passwordFound = $false
foreach ($pwd in $passwords) {
    $result = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File | Select-String -Pattern $pwd -SimpleMatch | Select-Object -First 1
    if ($result) {
        Write-Host "  WARNING: Found '$pwd'" -ForegroundColor Red
        $passwordFound = $true
    }
}
if (-not $passwordFound) {
    Write-Host "  ✓ No passwords found" -ForegroundColor Green
}

# Check for usernames
Write-Host "`n2. Checking for usernames..." -ForegroundColor Yellow
$usernames = @('henribo', 'adminhb', 'slashww3')
$usernameFound = $false
foreach ($user in $usernames) {
    $count = (Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File | Select-String -Pattern $user -SimpleMatch | Measure-Object).Count
    if ($count -gt 0) {
        Write-Host "  INFO: Found '$user' in $count locations (may be in comments)" -ForegroundColor Yellow
        $usernameFound = $true
    }
}
if (-not $usernameFound) {
    Write-Host "  ✓ No usernames found" -ForegroundColor Green
}

# Check for domains
Write-Host "`n3. Checking for domain names..." -ForegroundColor Yellow
$domains = @('bcxcloud.com', 'bcxonline.com', 'bcx.co.za')
$domainFound = $false
foreach ($domain in $domains) {
    $count = (Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File | Select-String -Pattern $domain -SimpleMatch | Measure-Object).Count
    if ($count -gt 0) {
        Write-Host "  INFO: Found '$domain' in $count locations" -ForegroundColor Yellow
        $domainFound = $true
    }
}
if (-not $domainFound) {
    Write-Host "  ✓ No domain names found" -ForegroundColor Green
}

# Check for email
Write-Host "`n4. Checking for email addresses..." -ForegroundColor Yellow
$emails = @('slashww3@gmail.com', 'henribo@bcxonline.com')
$emailFound = $false
foreach ($email in $emails) {
    $result = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File | Select-String -Pattern $email -SimpleMatch | Select-Object -First 1
    if ($result) {
        Write-Host "  WARNING: Found '$email'" -ForegroundColor Red
        $emailFound = $true
    }
}
if (-not $emailFound) {
    Write-Host "  ✓ No email addresses found" -ForegroundColor Green
}

Write-Host "`nVerification complete!`n" -ForegroundColor Cyan
