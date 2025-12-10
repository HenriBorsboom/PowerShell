# PowerShell Script Sanitization Tool
# This script sanitizes sensitive information from PowerShell scripts before publishing to GitHub

param(
    [string]$SourcePath = "c:\Users\slash\OneDrive\Documents\PowerShell",
    [switch]$WhatIf = $false
)

# Initialize counters
$script:FilesProcessed = 0
$script:FilesModified = 0
$script:TotalReplacements = 0
$script:ReplacementLog = @()

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Color
}

function Process-File {
    param(
        [string]$FilePath
    )
    
    $script:FilesProcessed++
    $fileModified = $false
    $fileReplacements = 0
    
    try {
        # Read file content
        $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($content)) {
            return
        }
        
        $originalContent = $content
        
        # Apply replacements in order (specific to general)
        
        # 1. Passwords (CRITICAL)
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourProxyPassword', 'YourProxyPassword')
        $content = $content.Replace('YourEmailPassword', 'YourEmailPassword')
        
        # 2. Specific domain\username combinations
        $content = $content.Replace('DOMAIN1\username', 'DOMAIN1\username')
        $content = $content.Replace('DOMAIN2\username', 'DOMAIN2\username')
        $content = $content.Replace('DOMAIN3\adminuser', 'DOMAIN3\adminuser')
        
        # 3. Service accounts
        $content = $content.Replace('DOMAIN2\svc-admin', 'DOMAIN2\svc-admin')
        $content = $content.Replace('DOMAIN2\svc-web-admin', 'DOMAIN2\svc-web-admin')
        $content = $content.Replace('DOMAIN2\svc-web-fso', 'DOMAIN2\svc-web-fso')
        $content = $content.Replace('DOMAIN2\svc-web-fsu', 'DOMAIN2\svc-web-fsu')
        $content = $content.Replace('DOMAIN2\svc-web-csu', 'DOMAIN2\svc-web-csu')
        $content = $content.Replace('DOMAIN2\svc-web-mn', 'DOMAIN2\svc-web-mn')
        $content = $content.Replace('DOMAIN2\svc-web-pb', 'DOMAIN2\svc-web-pb')
        $content = $content.Replace('DOMAIN2\svc-web-fe', 'DOMAIN2\svc-web-fe')
        $content = $content.Replace('DOMAIN2\svc-web-ww', 'DOMAIN2\svc-web-ww')
        $content = $content.Replace('svc_scvmm_action_dev', 'svc_scvmm_action_dev')
        $content = $content.Replace('svc_esig_scvmm', 'svc_esig_scvmm')
        $content = $content.Replace('svc_scvmm_action', 'svc_scvmm_action')
        $content = $content.Replace('svc_orchestrator', 'svc_orchestrator')
        
        # 4. Email addresses (before domain replacements)
        $content = $content.Replace('user@gmail.com', 'user@example.com')
        $content = $content.Replace('username@domain2.local', 'user@domain2.local')
        $content = $content.Replace('user@company.com', 'user@company.com')
        $content = $content.Replace('reports@domain1.local', 'reports@domain1.local')
        $content = $content.Replace('admin@company.com', 'admin@company.com')
        $content = $content.Replace('developer@example.com', 'developer@example.com')
        
        # 5. Specific server names
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
        
        # 6. IP addresses (using regex for precision)
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
        
        # 7. Domain names (after specific server names, use regex for word boundaries)
        $content = $content -replace 'websites\.domain2\.com', 'websites.domain2.local'
        $content = $content -replace 'hosting\.domain1\.com', 'hosting.domain1.local'
        $content = $content -replace 'pubapi\.domain1\.com', 'pubapi.domain1.local'
        $content = $content -replace 'domain1\.com', 'domain1.local'
        $content = $content -replace 'domain2\.com', 'domain2.local'
        $content = $content -replace 'bcx\.co\.za', 'company.com'
        
        # 8. Generic usernames (after specific combinations)
        $content = $content.Replace('localadmin', 'localadmin')
        $content = $content.Replace('LocalAdmin', 'LocalAdmin')
        $content = $content -replace 'username\.AFRICA', 'username'
        $content = $content.Replace('username', 'username')
        $content = $content.Replace('username', 'username')
        $content = $content.Replace('adminuser', 'adminuser')
        $content = $content.Replace('AdminUser', 'AdminUser')
        $content = $content.Replace('user', 'user')
        
        # 9. File paths (using regex)
        $content = $content -replace '\\\\APPSERVER101\\', '\\APPSERVER101\'
        $content = $content -replace 'C:\\Users\\username\.AFRICA\\', 'C:\Users\username\'
        $content = $content -replace 'C:\\Users\\username\\', 'C:\Users\username\'
        $content = $content -replace 'C:\\Users\\username\\', 'C:\Users\username\'
        $content = $content -replace 'c:\\users\\username\\', 'c:\users\username\'
        
        # 10. Domain references (generic, using word boundaries)
        $content = $content -replace '\bNTDOMAIN\b', 'DOMAIN3'
        $content = $content.Replace('domain1', 'domain1')
        $content = $content.Replace('domain2', 'domain2')
        $content = $content.Replace('Domain1', 'Domain1')
        $content = $content.Replace('Domain2', 'Domain2')
        
        # Check if file was modified
        if ($content -ne $originalContent) {
            $fileModified = $true
            $fileReplacements = ($originalContent.Length - $content.Length).ToString()
            
            # Write back if not in WhatIf mode
            if (-not $WhatIf) {
                Set-Content -Path $FilePath -Value $content -NoNewline -ErrorAction Stop
                $script:FilesModified++
                $script:TotalReplacements++
                Write-ColorOutput "  ✓ Modified: $(Split-Path $FilePath -Leaf)" -Color Green
            }
            else {
                Write-ColorOutput "  [WhatIf] Would modify: $(Split-Path $FilePath -Leaf)" -Color Yellow
            }
        }
        
    }
    catch {
        Write-ColorOutput "  ✗ Error processing $(Split-Path $FilePath -Leaf): $($_.Exception.Message)" -Color Red
    }
}

# Main execution
Write-ColorOutput "`n========================================" -Color Cyan
Write-ColorOutput "PowerShell Script Sanitization Tool" -Color Cyan
Write-ColorOutput "========================================`n" -Color Cyan

if ($WhatIf) {
    Write-ColorOutput "Running in WhatIf mode - no files will be modified`n" -Color Yellow
}

Write-ColorOutput "Source Path: $SourcePath" -Color White
Write-ColorOutput "Scanning for PowerShell files...`n" -Color White

# Get all .ps1 files
$files = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File -ErrorAction SilentlyContinue

Write-ColorOutput "Found $($files.Count) PowerShell files`n" -Color White
Write-ColorOutput "Processing files...`n" -Color White

# Process each file
$counter = 0
foreach ($file in $files) {
    $counter++
    if ($counter % 50 -eq 0) {
        Write-ColorOutput "  Progress: $counter / $($files.Count) files..." -Color Cyan
    }
    Process-File -FilePath $file.FullName
}

# Summary
Write-ColorOutput "`n========================================" -Color Cyan
Write-ColorOutput "Sanitization Complete" -Color Cyan
Write-ColorOutput "========================================`n" -Color Cyan

Write-ColorOutput "Files Processed: $script:FilesProcessed" -Color White
Write-ColorOutput "Files Modified: $script:FilesModified" -Color Green

Write-ColorOutput "`nSanitization completed successfully!`n" -Color Green
