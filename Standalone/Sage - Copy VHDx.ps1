$50Servers = (
"VIP-CLOUD-NAGIOS", `
"VIP-CLOUD-BCSG")
$75Servers = (
"VIP-CLOUD-IDL", `
"VIP-Cloud-Medscheme", `
"VIP-CLOUD-SAMEngineering", `
"VIP-Cloud_Citrix_Secure_Gateway1", `
"VIP-CLOUD-BDC", `
"VIP-Cloud-XenApp1", `
"VIP-Cloud-XenApp2", `
"VIP-CLOUD-PPL", `
"VIP-Cloud-MangolongoloTransport", `
"VIP-Cloud-HRToolbox", `
"VIP-CLOUD-FGF", `
"VIP-MORE", `
"VIP-CREATIVE", `
"VIP-CLOUD-DEUTS", `
"VIP-CLOUD-DB", `
"VIP-PG_LABOUR", `
"VIP-CLOUD-WPACK", `
"VIP-CLOUD-PSC", `
"VIP-CLOUD-MACSF", `
"VIP-CONVISTA", `
"VIP-TRIDENT", `
"VIP-MRM", `
"VIP-RUSMAR", `
"VIP-MOTION", `
"VIP-PENFORD", `
"VIP-RG_CONS", `
"VIP-Cloud-Medscheme2", `
"VIP-MEDSCHEME", `
"VIP-ARMADA", `
"VIP-SPACE", `
"VIP-DUMMY", `
"VIP-SACLAWA", `
"VIP-JWT", `
"VIP-FALCORP", `
"VIP-SYNERGY", `
"VIP-CLOUD-FTP", `
"VIP-AFB", `
"VIP-GP_CONS", `
"VIP-CAMBRIDGE", `
"VIP-STUDIO")
$90Servers = (
"VIP-LEAD")
$100Servers = (
"VIP-RECKITT", `
"VIP-FISHING", `
"VIP-DEMO-ESS", `
"VIP-COAL", `
"VIP-GPI", `
"VIP-AXIOMATIC", `
"VIP-DONAVENTA", `
"VIP-REALPAY", `
"VIP-VALE")
$150Servers = (
"VIP-Cloud-CPGP", `
"VIP-CLOUD-QLINK", `
"VIP-Cloud-ESS", `
"VIP-CLOUD-GMT", `
"VIP-CLOUD-IZAZI", `
"VIP-CLOUD-BIC", `
"VIP-CLOUD-ASCENT", `
"VIP-CLOUD-H2R", `
"VIP-CLOUD-SRAS", `
"VIP-CLOUD-TEST", `
"VIP-Limberger", `
"VIP-BINGO", `
"VIP-WESTERN", `
"VIP-P-CORP", `
"VIP-VETUS", `
"VIP-OCTOGEN")
$200Servers = (
"VIP-TFSE", `
"VIP-CORREDOR", `
"VIP-MOTHERS", `
"VIP-TAXI", `
"VIP-ENSIGHT", `
"VIP-FCB", `
"VIP-PERNOD", `
"VIP-HERITAGE", `
"VIP-GAUTENG", `
"VIP-LIQUID", `
"VIP-TERRASAN")
$300Servers = (
"VIP-Cloud-SCCM", `
"VIP-CURO", `
"VIP-CLOUD-STORTECH", `
"VIP-CLOUD-FOCUS", `
"VIP-CLOUD-QSA", `
"VIP-CLOUD-MQA", `
"VIP-LDE", `
"VIP-CLOUD-BAR", `
"VIP-CLOUD-FFC", `
"VIP-EFKON", `
"VIP-GearHold", `
"VIP-ASSET", `
"VIP-ELS", `
"VIP-VIKING", `
"VIP-HRM")
$375Servers = (
"VIP-Cloud-SQL")

Function CopyVHDs {
$Success = $true
Write-Host "Copying 50GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $50Servers.Count
ForEach ($Server in $50Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "75Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\75Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #50
Write-Host "Copying 75GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $75Servers.Count
ForEach ($Server in $75Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "75Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\75Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #75
Write-Host "Copying 90GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Count = 1
$Counter = $90Servers.Count
ForEach ($Server in $90Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "90Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\90Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #90
Write-Host "Copying 100GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $100Servers.Count
ForEach ($Server in $100Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "100Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\100Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #100
Write-Host "Copying 150GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $150Servers.Count
ForEach ($Server in $150Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "150Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\150Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #150
Write-Host "Copying 200GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $200Servers.Count
ForEach ($Server in $200Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "200Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\200Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #200
Write-Host "Copying 300GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $300Servers.Count
ForEach ($Server in $300Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "300Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\300Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #300
Write-Host "Copying 375GB VHDs" -foreGround Yellow
If ($Success -eq $true) {
$Counter = 1
$Count = $375Servers.Count
ForEach ($Server in $375Servers) {
    Write-Host "$Counter/$Count - " -NoNewline
    Try {
        Write-Host "Copying " -NoNewline
        Write-Host "375Fixed.VHDX" -NoNewline -ForegroundColor Yellow
        Write-Host " to " -NoNewline
        Write-Host "$Server" -NoNewline -ForegroundColor Cyan
        Write-Host " - " -NoNewline
            $Empty = Copy-Item -Path "C:\ClusterStorage\Volume10\375Fixed.vhdx" -Destination "C:\ClusterStorage\Volume1\$Server" -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        Write-Output $_
        $Success = $false
        Break
    }
    $Counter ++
}
} #375
}
Function CreateVM {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMName, `
        [Parameter(Mandatory=$true,Position=1)]
        [Int64] $MemoryinGB, `
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMPath, `
        [Parameter(Mandatory=$true,Position=1)]
        [Int64] $vCPUCount, `
        [Parameter(Mandatory=$true,Position=1)]
        [String] $VMVHD)

    Write-Host "  Create VM - $VMName - " -NoNewLine; 
        $Empty = New-VM -Name "$VMName" -MemoryStartupBytes ($MemoryinGB * 1024 * 1024 * 1024) -NoVHD -SwitchName ConvergedHyperSwitch -Path $VMPath -Generation 1 -ErrorAction Stop
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "  Set VM Details - $VMName - " -NoNewLine; 
        $Empty = Set-VM -Name "$VMName" -ProcessorCount $vCPUCount -MemoryMinimumBytes ($MemoryinGB * 1024 * 1024 * 1024) -MemoryStartupBytes ($MemoryinGB * 1024 * 1024 * 1024) -MemoryMaximumBytes ($MemoryinGB * 1024 * 1024 * 1024) -AutomaticStartAction Nothing -AutomaticStopAction TurnOff -DynamicMemory -ErrorAction Stop; 
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "  Set VM BIOS - $VMName - " -NoNewLine; 
        $Empty = Set-VMBios -EnableNumLock -VMName "$VMName" -ErrorAction Stop; 
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "  Enable Guest Service - $VMName - " -NoNewLine; 
        $Empty = Enable-VMIntegrationService -Name "Guest Service Interface" -VMName "$VMName" -ErrorAction Stop; 
    Write-Host "Complete" -ForegroundColor Green

    Write-Host "  Add VHD - $VMName - " -NoNewLine; 
        $Empty = Add-VMHardDiskDrive -VMName "$VMName" -Path $VMVHD -ErrorAction Stop; 
    Write-Host "Complete" -ForegroundColor Green
}

#CreateVM -VMName "Name" -MemoryinGB "gb" -VMPath "path" -vCPUCount "numb" -VMVHD "vhdpath"
CopyVHDs