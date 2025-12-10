Function Get-HyperVSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $VMHost = $env:COMPUTERNAME)

    # VMHost can be passed to the function but defaults to the localhost
    # Determine OS of host to determine Namespace
    # Get all VMs
    # Cycle through VMs to determine if snapshots exist
    # If snapshot is older than 7 days, alert critical, otherwise warning
    # If more than 0 snapshots exist, global icon is set to warning
    # If age of any snapshot exceeds 7 days, global icon is to Critical

    $ReportSnapshots        = @()
    $SnapshotsOldAgeCounter = 0

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
    Return $ReportSnapshots | Select-Object VM, Name, CreationTime, Age, Health
}