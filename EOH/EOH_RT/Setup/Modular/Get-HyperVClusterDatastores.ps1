Function Get-HyperVClusterDatastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
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

    $Datastores       = Get-ClusterSharedVolume -Cluster $Cluster
    $ReportDatastores = @()
    $WarningStores    = $False
    $CriticalStores   = $False
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
    Return $ReportDatastores | Select-Object Name, FreeSpace, Capacity, FreePerc, HealthIcon
}