# Sanitization Script - Batch 3: Domains, Servers, IPs, Emails
$SourcePath = "c:\Users\slash\OneDrive\Documents\PowerShell"
$files = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File
$modified = 0

Write-Host "Processing $($files.Count) files for domains, servers, IPs, emails..." -ForegroundColor Cyan

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($content)) { continue }
        
        $original = $content
        
        # Email addresses (before domain replacements)
        $content = $content.Replace('user@example.com', 'user@example.com')
        $content = $content.Replace('user@domain2.local', 'user@domain2.local')
        $content = $content.Replace('user@company.com', 'user@company.com')
        $content = $content.Replace('reports@domain1.local', 'reports@domain1.local')
        $content = $content.Replace('admin@company.com', 'admin@company.com')
        $content = $content.Replace('developer@example.com', 'developer@example.com')
        
        # Specific server names (before domain replacements)
        $content = $content.Replace('APPSERVER101', 'APPSERVER101')
        $content = $content.Replace('APPSERVER103', 'APPSERVER103')
        $content = $content.Replace('VMSERVER112', 'VMSERVER112')
        $content = $content.Replace('VMSERVER201', 'VMSERVER201')
        $content = $content.Replace('WEBSERVER101', 'WEBSERVER101')
        $content = $content.Replace('WEBSERVER102', 'WEBSERVER102')
        $content = $content.Replace('WEBSERVER103', 'WEBSERVER103')
        $content = $content.Replace('WEBSERVER104', 'WEBSERVER104')
        $content = $content.Replace('WEBSERVER105', 'WEBSERVER105')
        $content = $content.Replace('WEBSERVER106', 'WEBSERVER106')
        $content = $content.Replace('WEBSERVER107', 'WEBSERVER107')
        $content = $content.Replace('WEBSERVER108', 'WEBSERVER108')
        $content = $content.Replace('TSSERVER201', 'TSSERVER201')
        $content = $content.Replace('WORKSTATION01', 'WORKSTATION01')
        $content = $content.Replace('WORKSTATION', 'WORKSTATION')
        $content = $content.Replace('BACKUPSERVER01', 'BACKUPSERVER01')
        $content = $content.Replace('FILESERVER01', 'FILESERVER01')
        $content = $content.Replace('FILESERVER01', 'FILESERVER01')
        
        # IP addresses
        $content = $content -replace '165\.233\.41\.190', '203.0.113.10'
        $content = $content -replace '165\.233\.41\.182', '203.0.113.11'
        $content = $content -replace '165\.233\.41\.183', '203.0.113.12'
        $content = $content -replace '165\.233\.41\.166', '203.0.113.13'
        $content = $content -replace '165\.233\.41\.167', '203.0.113.14'
        $content = $content -replace '165\.233\.41\.186', '203.0.113.15'
        $content = $content -replace '165\.233\.41\.185', '203.0.113.16'
        $content = $content -replace '165\.233\.41\.188', '203.0.113.17'
        $content = $content -replace '165\.233\.158\.183', '198.51.100.10'
        $content = $content -replace '165\.233\.158\.181', '198.51.100.11'
        $content = $content -replace '10\.10\.145\.86', '10.0.145.86'
        $content = $content -replace '10\.12\.16\.12', '10.1.16.12'
        
        # Domain names (after specific server names)
        $content = $content -replace 'websites\.domain2\.com', 'websites.domain2.local'
        $content = $content -replace 'hosting\.domain1\.com', 'hosting.domain1.local'
        $content = $content -replace 'pubapi\.domain1\.com', 'pubapi.domain1.local'
        $content = $content -replace 'domain1\.com', 'domain1.local'
        $content = $content -replace 'domain2\.com', 'domain2.local'
        $content = $content -replace 'bcx\.co\.za', 'company.com'
        
        # File paths
        $content = $content -replace '\\\\APPSERVER101\\', '\\APPSERVER101\'
        $content = $content -replace 'C:\\Users\\henribo\.AFRICA\\', 'C:\Users\username\'
        $content = $content -replace 'C:\\Users\\HenriBo\\', 'C:\Users\username\'
        $content = $content -replace 'C:\\Users\\henribo\\', 'C:\Users\username\'
        $content = $content -replace 'c:\\users\\henribo\\', 'c:\users\username\'
        
        # Domain references (generic)
        $content = $content -replace '\bNTDOMAIN\b', 'DOMAIN3'
        $content = $content.Replace('domain1', 'domain1')
        $content = $content.Replace('domain2', 'domain2')
        $content = $content.Replace('Domain1', 'Domain1')
        $content = $content.Replace('Domain2', 'Domain2')
        
        if ($content -ne $original) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $modified++
            if ($modified % 50 -eq 0) {
                Write-Host "  Modified $modified files..." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "Batch 3 Complete: Modified $modified files" -ForegroundColor Green
