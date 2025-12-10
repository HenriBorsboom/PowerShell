# Path to the patches
$WsusPath = "D:\WSUS\WsusContent"

# Path to VHDx-file
$vhdxPath = "D:\win.vhdx"

# Mount the image
#Mount-DiskImage -ImagePath "$vhdxPath" -Access ReadWrite
Mount-WindowsImage -Path d:\temp -ImagePath D:\win.vhdx -Index 1 -ScratchDirectory d:\temp2

$updates = get-childitem -Recurse -Path $WsusPath | where {($_.extension -eq ".msu") -or ($_.extension -eq ".cab")} | select fullname
$x = 1
foreach($update in $updates) {
    Try {
        Write-Host "$x - Patch: " $update.FullName " - " -NoNewline
        $empty = Add-WindowsPackage -PackagePath $update.FullName -Path d:\temp -ErrorAction Stop -WarningAction SilentlyContinue -ScratchDirectory d:\temp2
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
    $x ++
}
Write-Host "Complete"
# Dismount the image
#Dismount-WindowsImage