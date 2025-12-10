Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory=$true,Position=2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
#region Required Variables
    $VHDPath = "D:\Management Library\Virtual Hard Disks"
    $WSUSContent = "D:\WSUS\WsusContent"
    $LibraryFolder = Get-ChildItem $VHDPath -Recurse -Include *.vhdx
    $VHDMountFolder = "D:\Patching\VHDMount"
    $ScratchFolder = "D:\Patching\Scratch"
#endregion
$VHDCount = $LibraryFolder.Count
$VHDCounter = 1
$TotalStartTime = Get-Date
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""
Write-Host "##################################################################### " -NoNewline
Write-Host $TotalStartTime.ToLongTimeString() -ForegroundColor Yellow
    
ForEach ($VHD in $LibraryFolder.FullName) {
    $StartTime = Get-Date
    Write-Host "########################################################################### " -NoNewline
    Write-Host "$VHDCounter\$VHDCount" -ForegroundColor Red
    D:\Patching\Apply-WSUSPatches.ps1 `
        -WSUSContentSharePath $WSUSContent `
        -VHDFile $VHD `
        -TemporaryDirectory $VHDMountFolder `
        -ScratchDirectory $ScratchFolder
    $EndTime = Get-Date
    Write-Host "##################################################################### " -NoNewline; 
    Write-Host $EndTime.ToLongTimeString() -ForegroundColor Yellow -NoNewline
    $Duration = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
    Write-Host " Duration: " -NoNewline
    Write-Host $Duration -ForegroundColor Green
    $VHDCounter ++
}
$TotalEndTime = Get-Date
$TotalDuration = Get-TotalTime -StartTime $TotalStartTime -EndTime $TotalEndTime
Write-Host "Total Duration: " $TotalDuration