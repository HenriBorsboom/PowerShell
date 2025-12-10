Function Get-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $ReportAlarms = @()
            #VMs
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "VM"
                AlarmName     = "Test VM Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
            #Hosts
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Host"
                AlarmName     = "Test Host Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
            #Datastores
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Red"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[CriticalImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Yellow"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[WarningImage]"
            })
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                AlarmSource   = "Datastore"
                AlarmName     = "Test Datastore Alarm Name"
                OverallStatus = "Green"
                Time          = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                HealthIcon    = "[NonCriticalImage]"
            })
        }
        $False {
            $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
            $ReportAlarms = @()
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.OverallStatus -eq 'red') { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow') { $AlarmHealthIcon = "[WarningImage]" }
                If ($ActiveAlarm.Entity.Value -like "*host*") {
                    $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*VirtualMachine*") {
                    $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name
                }
                ElseIf ($ActiveAlarm.Entity.Type -like "*Datastore*") {
                    $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name
                }
                Else {
                    $AlarmSource = "Unknown"
                }
                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    AlarmSource   = $AlarmSource
                    AlarmName   = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                    OverallStatus = $ActiveAlarm.OverallStatus
                    Time = $ActiveAlarm.Time
                    HealthIcon = $AlarmHealthIcon
                })
            }
        }
    }
    If ($ReportAlarms.Count -gt 0) { $Global:AlarmImage = $CriticalImage48; $Global:AlarmIcon = "[CriticalImage]" }
    Else { $Global:AlarmImage = $NonCriticalImage48; $Global:AlarmIcon = "[NonCriticalImage]" }
    Return $ReportAlarms | Select-Object AlarmSource, AlarmName, OverallStatus, Time, HealthIcon
}
Function Get-vCenterHosts {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $HostUnhealthyCounter = 2
            $ReportHosts = @()
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 1"
                ConnectionState = 'Connected'
                PowerState      = 'PoweredOn'
                Health          = "OK"
                HealthIcon      = "[NonCriticalImage]"
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 2"
                ConnectionState = 'Not Connected'
                PowerState      = 'PoweredOff'
                Health          = "Fail"
                HealthIcon      = "[CriticalImage]"
            })
            $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                Name            = "Test Host 3"
                ConnectionState = 'Connected'
                PowerState      = 'PoweredOff'
                Health          = "Fail"
                HealthIcon      = "[WarningImage]"
            })
        }
        $False {
            $ESXHosts = Get-VMHost | Select-Object Name, ConnectionState, PowerState
            $ReportHosts = @()
            $HostUnhealthyCounter = 0
            ForEach ($ESXHost in $ESXHosts) {
                If ($ESXHost.ConnectionState -eq 'Connected' -and $ESXHost.PowerState -eq 'PoweredOn') {
                    $Health = "OK"
                    $HealthIcon = "[NonCriticalImage]"
                }
                Else {
                    $Health = "Fail"
                    $HostUnhealthyCounter += 1
                    $HealthIcon = "[CriticalImage]"
                }
                $ReportHosts += ,(New-Object -TypeName PSObject -Property @{
                    Name            = $ESXHost.Name
                    ConnectionState = $ESXHost.ConnectionState
                    PowerState      = $ESXHost.PowerState
                    Health          = $Health
                    HealthIcon      = $HealthIcon
                })
            }
        }
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
    Return $ReportHosts | Select-Object Name, ConnectionState, PowerState, Health, HealthIcon
}
Function Get-vCenterVMS {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $VMUnhealthyCounter = 2
            $ReportVMs = @()
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 1'
                IPAddress  = '1.1.1.1'
                Powerstate = 'PoweredOn'
                HealthIcon = '[NonCriticalImage]'
            })
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 2'
                IPAddress  = '2.2.2.2'
                Powerstate = 'PoweredOff'
                HealthIcon = '[CriticalImage]'
            })
            $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                Name       = 'Test VM 3'
                IPAddress  = '3.3.3.3'
                Powerstate = 'PoweredMissing'
                HealthIcon = '[WarningImage]'
            })
        }
        $False {
            $VMUnhealthyCounter = 0
            $ReportVMs = @()
            ForEach ($VM in (Get-VM | Select Name, PowerState, @{N="IPAddress";E={@($_.guest.IPAddress[0])}})) {
                If ($VM.PowerState -ne 'PoweredOn') {
                    $VMUnhealthyCounter += 1 
                    $VMHealthIcon = "[CriticalImage]" 
                }
                Else {
                    $VMHealthIcon = "[NonCriticalImage]"
                }
                $ReportVMs += ,(New-Object -TypeName PSObject -Property @{
                    Name       = $VM.Name
                    IPAddress  = $VM.IPAddress
                    Powerstate = $VM.PowerState
                    HealthIcon = $VMHealthIcon
                })
            }
        }
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
    Return $ReportVMs | Select Name, IPAddress, PowerState, HealthIcon
}
Function Get-vCenterSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    Switch ($Dummy) {
        $True {
            $SnapshotsOldAgeCounter = 1
            $ReportSnapshots = @()
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 1'
                Name       = 'Test Snapshot 1'
                Created    = (Get-Date -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date)).Days
                HealthIcon = '[NonCriticalImage]'
            })
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 2'
                Name       = 'Test Snapshot 2'
                Created    = ((Get-Date).AddDays(-3) -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date).AddDays(-3)).Days
                HealthIcon = '[WarningImage]'
            })
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VMName     = 'Test VM 3'
                Name       = 'Test Snapshot 3'
                Created    = ((Get-Date).AddDays(-8) -f "dd/MM/yyyy HH:mm:ss")
                Age        = ((Get-Date) - (Get-Date).AddDays(-8)).Days
                HealthIcon = '[CriticalImage]'
            })
        }
        $False {
            $Snapshots = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
            $ReportSnapshots = @()
            $SnapshotsOldAgeCounter = 0
            ForEach ($Snapshot in $Snapshots) {
                If (((Get-Date) - $Snapshot.Created).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon = "[WarningImage]"
                }

                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    VMName = $Snapshot.VM
                    Name = $Snapshot.Name
                    Created = $Snapshot.Created
                    Age = ((Get-Date) - $Snapshot.Created).Days
                    HealthIcon = $SnapshotHealthIcon
                })

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
    If ($SnapshotsOldAgeCounter -gt 0) {
        $Global:SnapshotImage = $CriticalImage48
        $Global:SnapshotIcon = "[CriticalImage]"
    }
    Return $ReportSnapshots | Select-Object VMName, Name, Created, Age, HealthIcon
}
Function Get-vCenterDatastores {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)
    
    Switch ($Dummy) {
        $True {
            $WarningStores     = $True
            $CriticalStores    = $True
            $ReportDatastores  = @()
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '1024'
                CapacityMB  = '1024'
                FreePerc    = '100'
                HealthIcon  = '[NonCriticalImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '204'
                CapacityMB  = '1024'
                FreePerc    = '20'
                HealthIcon  = '[WarningImage]'
            })
            $ReportDatastores += (New-Object -TypeName PSObject -Property @{
                Name        = 'Test Data Store 1'
                FreeSpaceMB = '102'
                CapacityMB  = '1024'
                FreePerc    = '10'
                HealthIcon  = '[CriticalImage]'
            })
        }
        $False {
            $Datastores = Get-Datastore
            $ReportDatastores = @()
            $WarningStores = $False
            $CriticalStores = $False
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
                    Name = $Datastore.Name
                    FreeSpaceMB = $Datastore.FreeSpaceMB
                    CapacityMB = $Datastore.CapacityMB
                    FreePerc = [Math]::Round(($Datastore.FreeSpaceMB / $Datastore.CapacityMB * 100), 0)
                    HealthIcon = $DatastoreHealth
                })
            }
            
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
    
    Return $ReportDatastores | Select-Object Name, FreeSpaceMB, CapacityMB, FreePerc, HealthIcon
}