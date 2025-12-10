Function Get-vCenterAlarms {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [Switch] $Dummy)

    # Dummy can be passed to the Function to generate dummy info
    # Gets all Triggered alarms
    # Cycle through triggered alarms and tags Critica;/Warning and determine Alarm Source - Host/VM/Datastore
    # If any alarm is tagged to the report, set the Global Alarm icon to Critical and the Global Alarm Image to Critical

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
                    HealthIcon = $AlarmHealthIcon
                })
            }
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

    Return $ReportAlarms | Select Source, Event, Category, Time, HealthIcon
}
