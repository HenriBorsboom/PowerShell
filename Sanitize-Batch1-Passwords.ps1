# Sanitization Script - Batch 1: Passwords
$SourcePath = "c:\Users\slash\OneDrive\Documents\PowerShell"
$files = Get-ChildItem -Path $SourcePath -Filter "*.ps1" -Recurse -File
$modified = 0

Write-Host "Processing $($files.Count) files for password sanitization..." -ForegroundColor Cyan

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
        if ([string]::IsNullOrEmpty($content)) { continue }
        
        $original = $content
        
        # Replace passwords
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourPasswordHere', 'YourPasswordHere')
        $content = $content.Replace('YourProxyPassword', 'YourProxyPassword')
        $content = $content.Replace('YourEmailPassword', 'YourEmailPassword')
        
        if ($content -ne $original) {
            Set-Content -Path $file.FullName -Value $content -NoNewline
            $modified++
            if ($modified % 10 -eq 0) {
                Write-Host "  Modified $modified files..." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Error: $($file.Name)" -ForegroundColor Red
    }
}

Write-Host "Batch 1 Complete: Modified $modified files" -ForegroundColor Green
