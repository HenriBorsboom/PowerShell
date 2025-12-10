Function Get-vCenterSnapShots {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    # Dummy can be passed to the Function to generate dummy info
    # Get all VMs and there Snapshots by VM, Name, Created
    # If snapshot is older than 7 days, alert critical, otherwise warning
    # If more than 0 snapshots exist, global icon is set to warning
    # If age of any snapshot exceeds 7 days, global icon is to Critical

    $ReportSnapshots        = @()
    $SnapshotsOldAgeCounter = 0

    Switch ($Dummy) {
        $True {
            $SnapshotsOldAgeCounter = 1
            $ReportSnapshots = @()
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
        $False {
            $Snapshots              = Get-VM | Get-Snapshot | Select-Object VM, Name, Created
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