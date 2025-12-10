# Backup Rotation Script using Robocopy
# Author: Henri
# Purpose: Maintain two cycles of backups (Full + Incrementals)
# Sources: E:\System Backups, C:\Python, C:\Anti

$Sources   = @(
    @{Path="E:\System Backups"; Name="SystemBackups"},
    @{Path="C:\Python";         Name="Python"},
    @{Path="C:\Anti";           Name="Anti"}
)

$DestRoot  = "D:\System Backups"
$LogPath   = ("C:\Logs\BackupSync - " + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + ".log")

# Ensure log folder exists
if (!(Test-Path (Split-Path $LogPath))) {
    New-Item -ItemType Directory -Path (Split-Path $LogPath) | Out-Null
}

# Determine day of week
$Today = (Get-Date).DayOfWeek

# Paths for cycles
$Cycle1 = Join-Path $DestRoot "Cycle1"
$Cycle2 = Join-Path $DestRoot "Cycle2"

# Function: Run Robocopy
function Run-Robocopy($src, $dst, $log) {
    robocopy $src $dst /MIR /FFT /R:3 /W:5 /Z /MT:8 /LOG+:$log
}

# Function: Rotate cycles on Monday
function Rotate-Cycles {
    if (Test-Path $Cycle1) {
        Write-Output "Deleting oldest cycle (Cycle1)..."
        Remove-Item $Cycle1 -Recurse -Force
    }
    if (Test-Path $Cycle2) {
        Write-Output "Promoting Cycle2 to Cycle1..."
        Rename-Item $Cycle2 "Cycle1"
    }
    Write-Output "Creating new Cycle2..."
    New-Item -ItemType Directory -Path $Cycle2 | Out-Null
}

# Main Logic
if ($Today -eq "Monday") {
    # Rotate cycles
    Rotate-Cycles

    foreach ($src in $Sources) {
        $FullDest = Join-Path $Cycle2 ("Full\" + $src.Name)
        if (!(Test-Path $FullDest)) { New-Item -ItemType Directory -Path $FullDest | Out-Null }
        Run-Robocopy $src.Path $FullDest $LogPath
    }
}
else {
    foreach ($src in $Sources) {
        $IncDest = Join-Path $Cycle2 ("Incrementals\" + $src.Name)
        if (!(Test-Path $IncDest)) { New-Item -ItemType Directory -Path $IncDest | Out-Null }
        Run-Robocopy $src.Path $IncDest $LogPath
    }
}

Write-Output "Backup sync completed for $Today."
