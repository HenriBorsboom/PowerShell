$ErrorActionPreference = 'Continue'
Import-Module FailoverClusters
Import-Module Hyper-V


Clear-Host

$Cluster = 'HTD-CLU-01'
Write-Host "Getting Cluster Nodes - " -NoNewline
$ClusterNodes = Get-ClusterNode -Cluster $Cluster
Write-Host "Complete" -ForegroundColor Green
$VMDetails = @()
For ($NodeI = 0; $NodeI -lt $ClusterNodes.Count; $NodeI ++) {
    Write-Host (($NodeI + 1).ToString() + '/' + $ClusterNodes.Count.toString() + ' - Getting VM on host - ') -NoNewline
    $VMs = Get-VM -ComputerName $ClusterNodes[$NodeI].Name | Select *
    Write-Host "Complete" -ForegroundColor Green
    For($VMi = 0; $VMi -lt $VMs.Count; $VMi ++) {
        Write-Host (($VMi + 1).ToString() + '/' + $VMs.Count.ToString() + ' - Getting Disk details of VM - ') -NoNewline
        For ($DiskI = 0; $Diski -lt $VMs[$VMi].HardDrives.Count; $DiskI ++) {
            Try { 
                $VHD = Get-VHD -ComputerName $ClusterNodes[$NodeI].Name -Path $VMs[$VMi].HardDrives[$DiskI].Path -ErrorAction Stop
                $VMDetails += , (New-Object -TypeName PSObject -Property @{
                    Cluster = $Cluster
                    Host = $ClusterNodes[$NodeI]
                    VMName = $VMs[$VMi].VMName
                    CheckpointFileLocation = $VMs[$VMi].CheckpointFileLocation
                    ConfigurationLocation = $VMs[$VMi].ConfigurationLocation
                    SmartPagingFilePath = $VMs[$VMi].SmartPagingFilePath
                    SnapshotFileLocation = $VMs[$VMi].SnapshotFileLocation
                    Path = $VMs[$VMi].Path
                    DiskPath = $VHD.Path
                    VHDType = $VHD.VhdType
                    FileSize = [Math]::Round($VHD.FileSize / 1024 / 1024 / 1024, 2)
                    Size = [Math]::Round($VHD.Size / 1024 / 1024 / 1024, 2)
                })
            }
            Catch {
                $VMDetails += , (New-Object -TypeName PSObject -Property @{
                    Cluster = $Cluster
                    Host = $ClusterNodes[$NodeI]
                    VMName = $VMs[$VMi].VMName
                    CheckpointFileLocation = $VMs[$VMi].CheckpointFileLocation
                    ConfigurationLocation = $VMs[$VMi].ConfigurationLocation
                    SmartPagingFilePath = $VMs[$VMi].SmartPagingFilePath
                    SnapshotFileLocation = $VMs[$VMi].SnapshotFileLocation
                    Path = $null
                    DiskPath = $null
                    VHDType = $null
                    FileSize = $null
                    Size = $null
                })
            }
            $VHD = $null
        }
        Write-Host "Complete" -ForegroundColor Green
    }

}
If (Test-Path c:\temp\maps.csv) {
    Remove-Item c:\temp\maps.csv
}
$VMDetails | Select Cluster, Host, VMName , CheckpointFileLocation, ConfigurationLocation, SmartPagingFilePath, SnapshotFileLocation, Path, DiskPath, VHDType, FileSize, Size | `
    Export-Csv -Delimiter ';' -Path c:\temp\maps.csv -NoClobber -NoTypeInformation
notepad c:\temp\maps.csv