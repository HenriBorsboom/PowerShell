Add-Type -AssemblyName System.Drawing, System.Windows.Forms

# --- Configuration ---
$FolderPath = "C:\Screenshots\TimedCapture" # Change this to your desired folder
$IntervalSeconds = 60 # 1 minute
# ---------------------

# Create the folder if it doesn't exist
If (-not (Test-Path $FolderPath)) {
    New-Item -Path $FolderPath -ItemType Directory | Out-Null
}

# Define a function to capture and save the screen
Function Get-DesktopScreenshot {
    param(
        [string]$Path
    )
    # 

    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $Bitmap = New-Object System.Drawing.Bitmap $Screen.Width, $Screen.Height
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $Graphics.CopyFromScreen($Screen.Left, $Screen.Top, 0, 0, $Screen.Size)
    
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $FileName = "Screenshot_$Timestamp.png"
    $FullPath = Join-Path -Path $Path -ChildPath $FileName
    
    $Bitmap.Save($FullPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $Graphics.Dispose()
    $Bitmap.Dispose()
    
    Write-Host "Screenshot saved to $FullPath"
}

# --- Main Loop ---
Write-Host "Starting timed screenshot capture. Press Ctrl+C to stop."
While ($true) {
    Get-DesktopScreenshot -Path $FolderPath
    Start-Sleep -Seconds $IntervalSeconds
}