Param (
    [Parameter(Mandatory=$False, Position=1)]						# Target System Must contain: SystemName, IPAddress, CommonName, Platform, Username, Password
    [Object[]] $ReportingEnvironment)	

Function Get-Alarms {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Environment)

    [DateTime] $StartDate = (Get-Date).AddDays(-1)
    [DateTime] $EndDate   = Get-Date

    $ActiveLogs = Get-WinEvent -ListLog * -ComputerName $Environment.'IP Address'  | Where-Object {$_.RecordCount -gt 0}
    $AllEvents = @()
    For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
        $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate; Level=2,3} -ErrorAction SilentlyContinue 
        $TotalEvents += $LogEvents.Count
        If ($LogEvents.Count -gt 0) {
            For ($EventI = 0; $EventI -lt $LogEvents.Count; $EventI ++) {
                If ($LogEvents[$EventI].Message -ne $null) {
                    If ($LogEvents[$EventI].Message.ToLower() -like "*hyper*" -or $LogEvents[$EventI].Message.ToLower() -like "*cluster*" ) { 
                        $AllEvents += ,($LogEvents[$EventI])
                    }
                }
            }
        }
        $LogEvents = $null
    }
    
    #Clasifies Collected alarms and add an Image variable that will later be changed to a image when processing the data into a HTML Table
    If ($AllEvents.Count -gt 0) {
        ForEach ($ActiveAlarm in $AllEvents) {
            Switch ($ActiveAlarm.LevelDisplayName) {
                'Error'    { $AlarmHealthIcon = "[CriticalImage]" }
                'Critical' { $AlarmHealthIcon = "[CriticalImage]" }
                'Warning'  { $AlarmHealthIcon = "[WarningImage]"  }
            }
                        
            $ReportAlarms += ,(New-Object -TypeName PSObject -Property @{
                Source   = $ActiveAlarm.ProviderName
                Event    = $ActiveAlarm.Message
                Category = $ActiveAlarm.LevelDisplayName
                Time     = $ActiveAlarm.TimeCreated
                Health   = $AlarmHealthIcon
            })
        }
    }
    Return $ReportAlarms | Select Source, Event, Category, Time, Health
}