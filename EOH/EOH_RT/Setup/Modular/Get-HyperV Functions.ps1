Function Get-HyperVAlarms {
        Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    $AllAlarms = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1);} -ComputerName $VMHost
    $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*" -and $_.LevelDisplayName -ne 'Information'}
    $ReportAlarms = @()
    ForEach ($ActiveAlarm in $ActiveAlarms) {
        If ($ActiveAlarm.LevelDisplayName -eq 'Error') { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning') { $AlarmHealthIcon = "[WarningImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Information') { Continue }
        $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
            AlarmSource   =  $ActiveAlarms.ProviderName
            AlarmName   = $ActiveAlarm.Message
            OverallStatus =  $ActiveAlarm.LevelDisplayName
            Time = $ActiveAlarm.TimeCreated
            HealthIcon = $AlarmHealthIcon
        }) | Select AlarmSource, AlarmName, OverallStatus, Time, HealthIcon
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage48; $Global:AlarmIcon = "[CriticalImage]" }
    Else { $Global:AlarmImage = $NonCriticalImage48; $Global:AlarmIcon = "[NonCriticalImage]" }
    Return $ReportAlarms
}
Function Get-HyperVHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($VMHost -ne $env:COMPUTERNAME) { $HyperVHost = (Get-VMHost -ComputerName $VMHost).Name }
    Else { $HyperVHost = $env:COMPUTERNAME }

    $ReportHosts = @()
    $HostUnhealthyCounter = 0

    Try {
        Test-Connection $HyperVHost -Quiet -ErrorAction Stop
        $Health = "OK"
        $HealthIcon = "[NonCriticalImage]"
    }
    Catch {
        $Health = "Fail"
        $HostUnhealthyCounter += 1
        $HealthIcon = "[CriticalImage]"
        }
    Finally {
        $ReportHosts = (New-Object -TypeName PSObject -Property @{
            Name            = $HyperVHost
            ConnectionState = 'Connected'
            PowerState      = 'Online'
            Health          = $Health
            HealthIcon      = $HealthIcon
        }) | Select-Object Name, ConnectionState, PowerState, Health, HealthIcon
    }

    If ($HostUnhealthyCounter -eq 0) {
        $Global:HostImage = $NonCriticalImage48
        $Global:HostIcon = "[NonCriticalImage]"
    }
    ElseIf ($HostUnhealthyCounter -lt ($ReportHosts.Count / 2)) {
        $Global:HostImage = $WarningImage48
        $Global:HostIcon = "[WarningImage]"
    }
    Else {
        $Global:HostImage = $CriticalImage48
        $Global:HostIcon = "[CriticalImage]"
    }
    Return $ReportHosts
}
Function Get-HyperVVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    $VMUnhealthyCounter = 0
    $ReportVMs = @()
    If ($VMHost -ne '') {
        $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
        If ($OSCaption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ($OSCaption -like '*201*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace  -ComputerName $VMHost
    }
    Else {
        If ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*201*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
    }
    ForEach ($VM in $VMs) {
        If ($VM.EnabledState -eq 3) {
            $VMUnhealthyCounter += 1
            $VMHealthIcon = "[CriticalImage]"
            $VMState = 'PoweredOff'
        }
        Else {
            $VMHealthIcon = "[NonCriticalImage]"
            $VMState = 'PoweredOn'
        }
        #Get IP Address
        If ($Namespace -eq 'root\virtualization') {
            $VMIPaddress = 'Not available on this host'
        }
        Else {
            $VMIpaddress = $vm.GetRelated("Msvm_KvpExchangeComponent").GuestIntrinsicExchangeItems | `
                ForEach-Object {
                    $GuestExchangeItemXml = ([XML]$_).SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text()='NetworkAddressIPv4']")
                    If ($GuestExchangeItemXml -ne $null) { 
                        $GuestExchangeItemXml.SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value
                    }    
                }
        }
        $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
            Name       = $VM.ElementName
            IPAddress  = $VMIpaddress
            Powerstate = $VMState
            HealthIcon = $VMHealthIcon
        })
    }
    If ($VMUnhealthyCounter -eq 0) {
        $Global:VMImage = $NonCriticalImage48
        $Global:VMIcon = "[NonCriticalImage]"
    }
    ElseIf ($VMUnhealthyCounter -lt ($VMs.Count / 2)) {
        $Global:VMImage = $WarningImage48
        $Global:VMIcon = "[WarningImage]"
    }
    Else {
        $Global:VMImage = $CriticalImage48
        $Global:VMIcon = "[CriticalImage]"
    }
    Return $ReportVMs | Select-Object Name, IPAddress, Powerstate, HealthIcon
}
Function Get-HyperVSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    $ReportSnapshots = @()
    $Snapshots = @()
    $SnapshotsOldAgeCounter = 0

    If ($VMHost -ne '') {
        $Snapshots = Get-VM -ComputerName $VMHost | Get-VMSnapshot | Select-Object VMName, Name, CreationTime
        ForEach ($Snapshot in $Snapshots) {
            If (((Get-Date) - $Snapshot.CreationTime).Days -gt 7) {
                $SnapshotsOldAgeCounter += 1
                $SnapshotHealthIcon = "[CriticalImage]"
            }
            Else {
                $SnapshotHealthIcon = "[WarningImage]"
            }

            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName = $Snapshot.VMName
                Name = $Snapshot.Name
                Created = $Snapshot.CreationTime
                Age = ((Get-Date) - $Snapshot.CreationTime).Days
                HealthIcon = $SnapshotHealthIcon
            }) | Select-Object VMName, Name, CreationTime, Age, HealthIcon

        }
    }
    Else {
        If ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2008*') {
            $Namespace = 'root\virtualization'
        }
        ElseIf ((Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption').Caption -like '*2012*') {
            $Namespace = 'root\virtualization\v2'
        }
        Else {
            $Namespace = 'root\virtualization'
        }
        $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
        ForEach ($VM in $VMS) {
            $Query = ("Select * From Msvm_ComputerSystem Where ElementName='" + $VM.ElementName + "'")
            $SourceVm = Get-WmiObject -Namespace $Namespace -Query $Query
            $Snapshots = Get-WmiObject -Namespace $Namespace -Query "Associators Of {$SourceVm} Where AssocClass=Msvm_ElementSettingData ResultClass=Msvm_VirtualSystemSettingData"
            If ($Snapshots -ne $null) {
                $SnapshotCreationTime = [Management.ManagementDateTimeConverter]::ToDateTime($Snapshots.CreationTime)
                #$SnapshotAge =
                If (((Get-Date) - $SnapshotCreationTime).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon = "[WarningImage]"
                }
                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    VMName = $VM.ElementName
                    Name = $Snapshots.ElementName
                    CreationTime = '{0:yyyy/MM/dd HH:mm:ss}' -f $SnapshotCreationTime
                    Age = ((Get-Date) - $SnapshotCreationTime).Days
                    HealthIcon = $SnapshotHealthIcon
                }) | Select-Object VMName, Name, CreationTime, Age, HealthIcon
            }
        }
    }

    If ($ReportSnapshots.Count -eq 0) {
        $Global:SnapshotImage = $NonCriticalImage48
        $Global:SnapshotIcon = "[NonCriticalImage]"
    }
    ElseIf ($ReportSnapshots.Count -gt 0) {
        $Global:SnapshotImage = $WarningImage48
        $Global:SnapshotIcon = "[WarningImage]"
    }
    If ($Global:SnapshotsOldAgeCounter -gt 0) {
        $Global:SnapshotImage = $CriticalImage48
        $Global:SnapshotIcon = "[CriticalImage]"
    }
    Return $ReportSnapshots
}
Function Get-HyperVDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost)

    If ($VMHost -ne '') {
        $Datastores = Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3" -ComputerName $VMHost
    }
    Else {
        $Datastores = Get-WmiObject -Query "Select DeviceID,Size,FreeSpace from Win32_LogicalDisk where DriveType = 3"
    }
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -ge 11 -and [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 20) {
            $WarningStores = $True
            $DatastoreHealth = "[WarningImage]"
        }
        ElseIf ([Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0) -le 10) {
            $CriticalStores = $True
            $DatastoreHealth = "[CriticalImage]"
        }
        Else {
            $DatastoreHealth = "[NonCriticalImage]"
        }
        $ReportDatastores += (New-Object -TypeName PSObject -Property @{
            Name = $Datastore.DeviceID
            FreeSpaceMB = $Datastore.FreeSpace
            CapacityMB = $Datastore.Size
            FreePerc = [Math]::Round(($Datastore.FreeSpace / $Datastore.Size * 100), 0)
            HealthIcon = $DatastoreHealth
        }) | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
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
    Return $ReportDatastores
}
Function Get-HyperVClusterDatastores {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Cluster)

    $Datastores = Get-ClusterSharedVolume -Cluster $Cluster
    $ReportDatastores = @()
    $WarningStores = $False
    $CriticalStores = $False
    ForEach ($Datastore in $Datastores) {
        If ([Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -gt 10 -and [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0) -lt 25) {
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
            Name = $Datastore.SharedVolumeInfo.FriendlyVolumeName
            FreeSpaceMB = $Datastore.SharedVolumeInfo.Partition.FreeSpace
            CapacityMB = $Datastore.SharedVolumeInfo.Partition.Size
            FreePerc = [Math]::Round(($Datastore.SharedVolumeInfo.Partition.FreeSpace / $Datastore.SharedVolumeInfo.Partition.Size * 100), 0)
            HealthIcon = $DatastoreHealth
        }) | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
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
    Return $ReportDatastores
}