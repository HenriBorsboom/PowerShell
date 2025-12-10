Function Get-SnapShots {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('HyperVCluster', 'HyperVStandalone', 'VMWare', 'Dummy')]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    
    $ReportSnapshots        = @()
    $SnapshotsOldAgeCounter = 0

    Switch ($Platform) {
        'HyperV' {
            $OSCaption = (Get-WmiObject -Class 'Win32_OperatingSystem' -Property 'Caption' -ComputerName $VMHost).Caption
            
            If ($OSCaption -like '*2008*')    { $Namespace = 'root\virtualization' }
            ElseIf ($OSCaption -like '*201*') { $Namespace = 'root\virtualization\v2' }
            Else                              { $Namespace = 'root\virtualization' }
    
            $VMs = Get-WmiObject -Query "Select * from MSVM_ComputerSystem Where Caption = 'Virtual Machine'" -Namespace $Namespace
            ForEach ($VM in $VMS) {
                $Query     = ("Select * From Msvm_ComputerSystem Where ElementName='" + $VM.ElementName + "'")
                $SourceVm  = Get-WmiObject -Namespace $Namespace -Query $Query
                $Snapshots = Get-WmiObject -Namespace $Namespace -Query "Associators Of {$SourceVm} Where AssocClass=Msvm_ElementSettingData ResultClass=Msvm_VirtualSystemSettingData"
                If ($Snapshots -ne $null) {
                    $SnapshotCreationTime = [Management.ManagementDateTimeConverter]::ToDateTime($Snapshots.CreationTime)
                    If (((Get-Date) - $SnapshotCreationTime).Days -gt 7) {
                        $SnapshotsOldAgeCounter += 1
                        $SnapshotHealthIcon = "[CriticalImage]"
                    }
                    Else {
                        $SnapshotHealthIcon = "[WarningImage]"
                    }
                    $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                        VM           = $VM.ElementName
                        Name         = $Snapshots.ElementName
                        CreationTime = '{0:yyyy/MM/dd HH:mm:ss}' -f $SnapshotCreationTime
                        Age          = ((Get-Date) - $SnapshotCreationTime).Days
                        Health       = $SnapshotHealthIcon
                    })
                }
            }
        }
        'VMWare' {
            $Snapshots = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
            ForEach ($Snapshot in $Snapshots) {
                If (((Get-Date) - $Snapshot.Created).Days -gt 7) {
                    $SnapshotsOldAgeCounter += 1
                    $SnapshotHealthIcon      = "[CriticalImage]"
                }
                Else {
                    $SnapshotHealthIcon      = "[WarningImage]"
                }

                $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                    VM           = $Snapshot.VM
                    Name         = $Snapshot.Name
                    CreationTime = $Snapshot.Created
                    Age          = ((Get-Date) - $Snapshot.Created).Days
                    Health       = $SnapshotHealthIcon
                })
            }
        }
        'Dummy' {
            $SnapshotsOldAgeCounter = 1
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VM           = 'Test VM 1'
                Name         = 'Test Snapshot 1'
                CreationTime = (Get-Date -f "dd/MM/yyyy HH:mm:ss")
                Age          = ((Get-Date) - (Get-Date)).Days
                Health       = '[NonCriticalImage]'
            }) # Non Critical
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VM           = 'Test VM 2'
                Name         = 'Test Snapshot 2'
                CreationTime = ((Get-Date).AddDays(-3) -f "dd/MM/yyyy HH:mm:ss")
                Age          = ((Get-Date) - (Get-Date).AddDays(-3)).Days
                Health       = '[WarningImage]'
            }) # Warning
            $ReportSnapshots += ,(New-Object -TypeName PSObject -Property @{
                VM           = 'Test VM 3'
                Name         = 'Test Snapshot 3'
                CreationTime = ((Get-Date).AddDays(-8) -f "dd/MM/yyyy HH:mm:ss")
                Age          = ((Get-Date) - (Get-Date).AddDays(-8)).Days
                Health       = '[CriticalImage]'
            }) # Critical
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
    Return $ReportSnapshots | Select-Object VM, Name, CreationTime, Age, Health
}