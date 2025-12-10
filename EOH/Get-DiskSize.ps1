Function Get-Disks {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server)

    $Properties = @("DeviceID","VolumeName","FreeSpaceGB","SizeGB","FreePercent", "FreeSpaceWarning")
    If ($Server -eq "") { 
        $Results = Get-WmiObject -Query "Select DeviceID,FreeSpace,Size,VolumeName from Win32_LogicalDisk WHERE DriveType = '3'"
    }
    Else {
        $Results = Get-WmiObject -Query "Select DeviceID,FreeSpace,Size,VolumeName from Win32_LogicalDisk WHERE DriveType = '3'" -ComputerName $Server
    }

    $Formatted = @()
    ForEach ($Drive in $Results) {
        If ([Math]::Round((($Drive.FreeSpace / 1024 / 1024 / 1024) / ($Drive.Size / 1024 / 1024 / 1024)) * 100) -lt 10) { $SpaceWarning = $True } Else {$SpaceWarning = $False}
        $Formatted += ,(New-Object -TypeName PSObject -Property @{
            "DeviceID"         = $Drive.DeviceID
            "VolumeName"       = $Drive.VolumeName
            "FreeSpaceGB"      = [Math]::Round($Drive.FreeSpace / 1024 / 1024 / 1024)
            "SizeGB"           = [Math]::Round($Drive.Size / 1024 / 1024 / 1024)
            "FreePercent"      = [Math]::Round((($Drive.FreeSpace / 1024 / 1024 / 1024) / ($Drive.Size / 1024 / 1024 / 1024)) * 100)
            "FreeSpaceWarning" = $SpaceWarning
            }
        )
    }
    $Formatted | Select $Properties | Format-Table
}

$Servers = @(
    "BL-BASE1", `
    "BL-BASE2", `
    "BL-BASE3", `
    "BL-BASE4")

ForEach ($Server in $Servers) {
    Write-Host $Server -ForegroundColor Green
    Get-Disks -Server $Server
}