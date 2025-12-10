Param (
    [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
    [Object[]] $ReportingEnvironment)	

Function Get-Alarms {
    $AllEvents = @()
    [Object[]] $ActiveAlarms = (Get-Datacenter).ExtensionData.TriggeredAlarmState
    If ($ActiveAlarms.Count -gt 0) {
        ForEach ($ActiveAlarm in $ActiveAlarms) {
            Switch ($ActiveAlarm.OverallStatus) {
                'red'    { $AlarmHealthIcon = "[CriticalImage]" }
                'yellow' { $AlarmHealthIcon = "[WarningImage]" }
            }
            
            Switch ($ActiveAlarm.Entity.Value) {
                "*host*"           { $AlarmSource = (Get-VMHost -Id $ActiveAlarm.Entity).Name }
                "*VirtualMachine*" { $AlarmSource = (Get-VM -Id $ActiveAlarm.Entity).Name }
                "*Datastore*"      { $AlarmSource = (Get-Datastore -Id $ActiveAlarm.Entity).Name }
                Default            { $AlarmSource = "Unknown" }
            }
            
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source     = $AlarmSource
                Event      = (Get-AlarmDefinition -Id $ActiveAlarm.Alarm).Name
                Category   = $ActiveAlarm.OverallStatus
                Time       = $ActiveAlarm.Time
                Health     = $AlarmHealthIcon
            })
        }
    }

    Return $ReportAlarms | Select Source, Event, Category, Time, Health
}