$VMNames = @(
    "2012-External-Wifi", `
    "2012-External-LAN", `
    "2012-Internal", `
    "2012-Private", `
    "2012-Monitor", `
    "2008-Wifi", `
    "2008-LAN", `
    "2008-Internal", `
    "2008-Private", `
    "2008-Monitor")
$VMSwitches = @(
    "External - Wifi", `
    "External - LAN", `
    "Internal", `
    "Private", `
    "Monitor")
$Base2008 = "C:\VM\Reference Disks\Base11A-WS08R2SP1.vhd"
$Base2012 = "C:\VM\Reference Disks\Base14A-WS12R2.vhd"
$VMCount = $VMNames.Count
$SwitchCount = $VMSwitches.Count
$VMCounter = 1
$SwitchCounter = 0

Try {
    For($VMId = 0; $VMId -lt $VMNames.Count; $VMId ++) {
        Write-Host "$VMCounter/$VMCount" -ForegroundColor Yellow
        If ($SwitchCounter -eq 5) {$SwitchCounter = 0}
        $VMName = $VMNames[$VMId]
        If ($VMName -like "*2008*") {$Base = $Base2008}
        ElseIf ($VMName -like "*2012*") {$Base = $Base2012}
        Else {Write-Host "not found"; Break}
        Write-Host "  Create Directory - $VMName - " -NoNewLine; $Empty = New-Item -Path "C:\VM\$VMName" -ItemType directory -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Create Differencing VHD - $VMName - " -NoNewLine; $Empty = New-VHD -ParentPath $Base -Path "C:\VM\$VMName\$VMName.vhd" -Differencing -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Create VM - $VMName - " -NoNewLine; $Empty = New-VM -Name "$VMName" -MemoryStartupBytes 2147483648 -NoVHD -SwitchName $VMSwitches[$SwitchCounter] -Path "C:\VM\$VMName" -Generation 1 -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Set VM Details - $VMName - " -NoNewLine; $Empty = Set-VM -Name "$VMName" -ProcessorCount 2 -MemoryMinimumBytes (1024*1024*512) -MemoryStartupBytes (1024*1024*512) -MemoryMaximumBytes (1024*1024*1024*4) -AutomaticStartAction Nothing -AutomaticStopAction TurnOff -DynamicMemory -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Set VM BIOS - $VMName - " -NoNewLine; $Empty = Set-VMBios -EnableNumLock -VMName "$VMName" -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Enable Guest Service - $VMName - " -NoNewLine; $Empty = Enable-VMIntegrationService -Name "Guest Service Interface" -VMName "$VMName" -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        Write-Host "  Add VHD - $VMName - " -NoNewLine; $Empty = Add-VMHardDiskDrive -VMName "$VMName" -Path "C:\VM\$VMName\$VMName.vhd" -ErrorAction Stop; Write-Host "Complete" -ForegroundColor Green
        $SwitchCounter ++
        $VMCounter ++
    }
}
Catch {
    Write-Output $_
    Break
}