Function Get-DiskSize {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Drive)
    $WMIQuery = "Select Size from Win32_LogicalDisk Where Caption = ""$Drive"""
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        $Size = [Math]::Round($WMIResults.Size / 1024 / 1024 / 1024)
        Return $Size
    }
    Catch { Return $false }
}
$Properties = @("DeviceID","VolumeName","FreeSpaceGB","SizeGB","FreePercent")
$Results = Get-WmiObject -Query "Select DeviceID,FreeSpace,Size,VolumeName from Win32_LogicalDisk WHERE DriveType = '3'"

(New-Object -TypeName PSObject -Property @{
    "DeviceID"   = $Results.DeviceID
    "FreeSpaceGB"  = [Math]::Round($Results.FreeSpace / 1024 / 1024 / 1024)
    "SizeGB"       = [Math]::Round($Results.Size / 1024 / 1024 / 1024)
    "FreePercent"  = [Math]::Round((($Results.FreeSpace / 1024 / 1024 / 1024) / ($Results.Size / 1024 / 1024 / 1024)) * 100)
    "VolumeName"   = $Results.VolumeName
}) | Select $Properties | Format-Table