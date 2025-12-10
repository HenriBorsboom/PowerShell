#Version 1.0
Function Get-HyperVAlarms {
    # VMHost can be passed to the function but defaults to the localhost
    # Gets all 1(Critical), 2(Error), 3(Warning) events for the past 24 hours from the System Log
    # Filter events only related to *HYPER* and *CLUSTER*
    # Cycle through events and tag Error/Critical/Warning if applicable
    # If any alarm is tagged to the report, set the Global Alarm icon to Critical and the Global Alarm Image to Critical
    Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $VMHost = $env:COMPUTERNAME)

    $AllAlarms = Get-WinEvent -FilterHashtable @{LogName='System';StartTime=(Get-Date).AddDays(-1);Level=(1..3);} -ComputerName $VMHost
    $ActiveAlarms = $AllAlarms | Where-Object {$_.Message -like "*hyper*" -or $_.Message -like "*cluster*"}
    $ReportAlarms = @()
    ForEach ($ActiveAlarm in $ActiveAlarms) {
        If ($ActiveAlarm.LevelDisplayName -eq 'Error')        { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Critical') { $AlarmHealthIcon = "[CriticalImage]" }
        ElseIf ($ActiveAlarm.LevelDisplayName -eq 'Warning')  { $AlarmHealthIcon = "[WarningImage]" }
        $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
            Source     = $ActiveAlarms.ProviderName
            Event      = $ActiveAlarm.Message
            Category   = $ActiveAlarm.LevelDisplayName
            Time       = $ActiveAlarm.TimeCreated
            HealthIcon = $AlarmHealthIcon
        })
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