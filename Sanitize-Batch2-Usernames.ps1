# Sanitization Script - Batch 2: Usernames and Domain Accounts
$SourcePath = "c:\Users\slash\OneDrive\Documents\PowerShell"
$files = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File
$modified = 0

Write-Host "Processing $($files.Count) files for username/domain sanitization..." -ForegroundColor Cyan

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($content)) { continue }
        
        $original = $content
        
        # Specific domain\username combinations (before generic)
        $content = $content.Replace('DOMAIN1\username', 'DOMAIN1\username')
        $content = $content.Replace('DOMAIN2\username', 'DOMAIN2\username')
        $content = $content.Replace('DOMAIN3\adminuser', 'DOMAIN3\adminuser')
        
        # Service accounts
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
        
        # Generic usernames (after specific combinations)
        $content = $content.Replace('localadmin', 'localadmin')
        $content = $content.Replace('LocalAdmin', 'LocalAdmin')
        $content = $content -replace 'username\.AFRICA', 'username'
        $content = $content.Replace('username', 'username')
        $content = $content.Replace('username', 'username')
        $content = $content.Replace('adminuser', 'adminuser')
        $content = $content.Replace('AdminUser', 'AdminUser')
        $content = $content.Replace('user', 'user')
        
        if ($content -ne $original) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $modified++
            if ($modified % 20 -eq 0) {
                Write-Host "  Modified $modified files..." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "Batch 2 Complete: Modified $modified files" -ForegroundColor Green
