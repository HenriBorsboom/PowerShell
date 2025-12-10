Function Get-Datastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('HyperVCluster', 'HyperVStandalone', 'VMWare', 'Dummy')]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $Cluster)

    Function Format-Size {
        Param (
            [Parameter(Mandatory=$True, Position=1)]
            [Int64] $Size)

        If ($Size -le 1024) { $FormattedSize = ($Size.ToString() + " B") }
        ElseIf ($Size -ge 1025 -and $Size -le 1048576) { $FormattedSize = [Math]::Round($Size / 1024, 2).ToString() + " KB" }
        ElseIf ($Size -ge 1048577 -and $Size -le 1073741824) { $FormattedSize = [Math]::Round($Size / 1024 / 1024, 2).ToString() + " MB" }
        ElseIf ($Size -ge 1073741825 -and $Size -le 1099511627776) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024, 2).ToString() + " GB" }
        ElseIf ($Size -ge 1099511627777 -and $Size -le 1125899906842624) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024 / 1024, 2).ToString() + " TB" }

        Return $FormattedSize
    }
   
    $WarningStores     = $False
    $CriticalStores    = $False
    $ReportDatastores  = @()

    Switch ($Platform) {
        'HyperVStandalone' {
            $Datastores = Get-WmiObject -Query "Select DeviceID, Size, FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost

            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -ge 11 -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 20) {
                    $WarningStores   = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 10) {
                    $CriticalStores   = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }

                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    Name      = $Datastore.DeviceID
                    FreeSpace = (Format-Size -Size $Datastore.FreeSpace)
                    Capacity  = (Format-Size -Size $Datastore.Size)
                    FreePerc  = [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)
                    Health    = $DatastoreHealth
                })
            }
        }
        'HyperVCluster' {
            $Datastores       = Get-ClusterSharedVolume -Cluster $Cluster
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -ge 11 -and [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le 20) {
                    $WarningStores = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -le 10) {
                    $CriticalStores = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    Name      = $Datastore.SharedVolumeInfo.FriendlyVolumeName
                    FreeSpace = (Format-Size -Size $Datastore.SharedVolumeInfo.Partition.FreeSpace)
                    Capacity  = (Format-Size -Size $Datastore.SharedVolumeInfo.Partition.Size)
                    FreePerc  = [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0)
                    Health    = $DatastoreHealth
                })
            }
        }
        'VMWare' {
            $Datastores = Get-Datastore
            ForEach ($Datastore in $Datastores) {
                If ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -ge 11 -and [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 2) -le 20) {
                    $WarningStores = $True
                    $DatastoreHealth = "[WarningImage]"
                }
                ElseIf ([Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0) -le 10) {
                    $CriticalStores = $True
                    $DatastoreHealth = "[CriticalImage]"
                }
                Else {
                    $DatastoreHealth = "[NonCriticalImage]"
                }
                $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                    Name      = $Datastore.Name
                    FreeSpace = (Format-Size -Size ($Datastore.FreeSpaceMB * 1024))
                    Capacity  = (Format-Size -Size ($Datastore.CapacityMB * 1024))
                    FreePerc  = [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0)
                    Health    = $DatastoreHealth
                })
            }
        }
        'Dummy' {
            $WarningStores     = $True
            $CriticalStores    = $True
            $ReportDatastores  = @()
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name      = 'Test Data Store 1'
                FreeSpace = '1024'
                Capacity  = '1024'
                FreePerc  = '100'
                Health    = '[NonCriticalImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name      = 'Test Data Store 1'
                FreeSpace = '204'
                Capacity  = '1024'
                FreePerc  = '20'
                Health    = '[WarningImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name      = 'Test Data Store 1'
                FreeSpace = '102'
                Capacity  = '1024'
                FreePerc  = '10'
                Health    = '[CriticalImage]'
            })
        }
    }
    If ($CriticalStores -eq $True) {
        $Global:DatastoreImage = $CriticalImage48
        $Global:DatastoreIcon = "[CriticalImage]"
    }
    ElseIf ($WarningStores -eq $True) {
        $Global:DatastoreImage = $WarningImage48
        $Global:DatastoreIcon = "[WarningImage]"
    }
    Else {
        $Global:DatastoreImage = $NonCriticalImage48
        $Global:DatastoreIcon = "[NonCriticalImage]"
    }
    
    Return $ReportDatastores | Select-Object Name, FreeSpace, Capacity, FreePerc, Health
}
