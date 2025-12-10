Function Get-HyperVDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    # VMHost can be passed to the function but defaults to the localhost
    # Get data stores from VMHost where the drive type is a physical drive
    # Cycle through data stores and determine free space %
    # If Free Space % between 11% - 20% the datastore is flagged as Warning
    # If Free Space % below 11% the datastore is flagged as Critical

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

    $ReportDatastores = @()

    $Datastores = Get-WmiObject -Query "Select DeviceID, Size, FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost
        
    $WarningStores  = $False
    $CriticalStores = $False
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