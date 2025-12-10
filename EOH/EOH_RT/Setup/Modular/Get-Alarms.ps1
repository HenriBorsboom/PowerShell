Function Get-Alarms {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet('HyperVCluster', 'HyperVStandalone', 'VMWare', 'Dummy')]
        [String] $Platform, `
        [Parameter(Mandatory=$False, Position=2)]
        [String] $VMHost = $env:COMPUTERNAME)

    If ($Platform -like 'Hyper*') { $Platform = 'HyperV' }
    $ReportAlarms = @()
    Switch ($Platform) {
        'HyperV' {
            $AllAlarms    = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1);Level=(1..3);} -ComputerName $VMHost
            $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*"}
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.LevelDisplayName -eq 'Error')        { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Critical') { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning')  { $AlarmHealthIcon = "[WarningImage]" }
                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    Source   = $ActiveAlarms.ProviderName
                    Event    = $ActiveAlarm.Message
                    Category = $ActiveAlarm.LevelDisplayName
                    Time     = $ActiveAlarm.TimeCreated
                    Health   = $AlarmHealthIcon
                })
            }
        }
        'VMWare' {
            $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
            ForEach ($ActiveAlarm in $ActiveAlarms) {
                If ($ActiveAlarm.OverallStatus -eq 'red')                  { $AlarmHealthIcon = "[CriticalImage]" }
                ElseIf ($ActiveAlarm.OverallStatus -eq 'yellow')           { $AlarmHealthIcon = "[WarningImage]" }
                
                If ($ActiveAlarm.Entity.Value -like "*host*")              { $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name }
                ElseIf ($ActiveAlarm.Entity.Type -like "*VirtualMachine*") { $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name }
                ElseIf ($ActiveAlarm.Entity.Type -like "*Datastore*")      { $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name }
                Else                                                       { $AlarmSource = "Unknown" }

                $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                    Source     = $AlarmSource
                    Event      = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                    Category   = $ActiveAlarm.OverallStatus
                    Time       = $ActiveAlarm.Time
                    Health     = $AlarmHealthIcon
                })
            }
        }
        'Dummy' {
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "VM"
                Event      = "Test VM Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
            #Hosts
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Host"
                Event      = "Test Host Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
            #Datastores
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Red"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[CriticalImage]"
            }) #Red
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Yellow"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[WarningImage]"
            }) #Yellow
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{ 
                Source     = "Datastore"
                Event      = "Test Datastore Alarm Name"
                Category   = "Green"
                Time       = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
                Health     = "[NonCriticalImage]"
            }) #Green
        }
    }
    If ($ReportAlarms.Count -gt 0) { `
        $Global:AlarmImage = $CriticalImage48
        $Global:AlarmIcon = "[CriticalImage]" 
    }
    Else { 
        $Global:AlarmImage = $NonCriticalImage48
        $Global:AlarmIcon = "[NonCriticalImage]"
    }

    Return $ReportAlarms | Select Source, Event, Category, Time, Health
}
Get-Alarms -Dummy
