Function Discard-VHD {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $MountedDirectory)

    Try {
        Write-Color "Dismounting and discarding changes on VHD mounted at ", $MountedDirectory, " - " -Color White, Cyan, White
            $empty = Dismount-WindowsImage -Discard -Path $MountedDirectory -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}

$VHD = "D:\Removed from VMM Library\Patched\Windows Server 2012 R2\Windows Server 2012 R2 Standard Gen 2.vhdx"
$Temp = "D:\Temp"
$WSUS = "APPSERVER103.domain2.local"

Discard-VHD -MountedDirectory "D:\Temp"