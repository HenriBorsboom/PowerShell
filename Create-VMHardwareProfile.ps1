Param(
    [Parameter(Mandatory=$true,Position=1)]
    [String] $HardwareProfileName, `
    [Parameter(Mandatory=$true,Position=2)]
    [String] $HardwareProfileDescription, `
    [Parameter(Mandatory=$true,Position=3)]
    [int64] $CoreCount, `
    [Parameter(Mandatory=$true,Position=4)]
    [int64] $MaximumMemory)

#region Common Functions
Function Debug{
    Param(
        [Parameter(Mandatory=$false,Position=1)]
        $Variable)
    
    If ($Variable -eq $null){
        $VariableDetails = "Empty Variable"
    }
    Else{
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c"){
        Return
    }
    Else{
        Exit 1
    }
}

Function Strip-Name{
    Param(
        [String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}

Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    Switch ($EndLine){
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
}

#endregion

Function Create-VMHardwareProfile{
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $HardwareProfileName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $HardwareProfileDescription, `
        [Parameter(Mandatory=$true,Position=3)]
        [int64] $CoreCount, `
        [Parameter(Mandatory=$true,Position=4)]
        [int64] $MaximumMemory)

    Write-Host -Text "Obtaining CPU Type - " -NoNewline
        $CPUType = Get-SCCPUType -VMMServer vmm01.domain2.local | where {$_.Name -eq "3.60 GHz Xeon (2 MB L2 cache)"}
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Color -Text "Creating Hardware Profile ",$HardwareProfileName, " - " -Color White, Cyan, Whit
        New-SCHardwareProfile -VMMServer vmm01.domain2.local -Owner "" `
            -CPUType $CPUType `
            -Name $HardwareProfileName `
            -Description $HardwareProfileDescription `
            -CPUCount $CoreCount `
            -MemoryMB $MaximumMemory `
            -DynamicMemoryEnabled $true `
            -DynamicMemoryMinimumMB 32 `
            -DynamicMemoryMaximumMB $MaximumMemory `
            -DynamicMemoryBufferPercentage 20 `
            -MemoryWeight 5000 `
            -VirtualVideoAdapterEnabled $false `
            -CPUExpectedUtilizationPercent 20 `
            -DiskIops 0 `
            -CPUMaximumPercent 100 `
            -CPUReserve 0 `
            -NumaIsolationRequired $false `
            -NetworkUtilizationMbps 0 `
            -CPURelativeWeight 100 `
            -HighlyAvailable $true `
            -DRProtectionRequired $false `
            -NumLock $true `
            -BootOrder "CD", "IdeHardDrive", "PxeBoot", "Floppy" `
            -CPULimitFunctionality $false `
            -CPULimitForMigration $false `
            -Generation 1 | Out-Null 
    Write-Host "Complete" -ForegroundColor Green
        
    Write-Color -Text "Obtaining ",$HardwareProfileName, " - " -Color White, Cyan, White
        $HardwareProfile = Get-SCHardwareProfile | Where-Object {$_.Name -eq $HardwareProfileName}
    Write-Host " Complete" -ForegroundColor Green
    
    Write-Color "Creating Network Adapter on ",$HardwareProfileName, " - " -Color White, Cyan, White
        New-SCVirtualNetworkAdapter -HardwareProfile $HardwareProfile -MACAddressType Dynamic -Synthetic -IPv4AddressType Dynamic -IPv6AddressType Dynamic | Out-Null
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Color "Creating SCSI Adapter on ",$HardwareProfileName, " - " -Color White, Cyan, White
        New-SCVirtualScsiAdapter -HardwareProfile $HardwareProfile -AdapterID 7 -ShareVirtualScsiAdapter $false -ScsiControllerType DefaultTypeNoType | Out-Null
    Write-Host "Complete" -ForegroundColor Green
    
    Write-Color "Creating DVD Drive on ",$HardwareProfileName, " - " -Color White, Cyan, White
        New-SCVirtualDVDDrive -HardwareProfile $HardwareProfile -Bus 1 -LUN 0 | Out-Null
    Write-Host "Complete" -ForegroundColor Green
}

Create-VMHardwareProfile -HardwareProfileName $HardwareProfileName -HardwareProfileDescription $HardwareProfileDescription -CoreCount $CoreCount -MaximumMemory $MaximumMemory