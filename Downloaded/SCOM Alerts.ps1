Clear-Host
#DailyAlertSummary.ps1
Import-Module OperationsManager
New-SCOMManagementGroupConnection -ComputerName SYSJHBOPSMGR.sysproza.net

#Get between dates Yesterday
$AlertDateYesterdayBegin = [DateTime]::Today.AddDays(-1)
$AlertDateYesterdayEnd = [DateTime]::Today.AddDays(-1).AddSeconds(86399)

#Get yesterday alerts
$YesterdayAlerts = @(get-scomalert | where {$_.TimeRaised -gt $AlertDateYesterdayBegin -and $_.TimeRaised -lt $AlertDateYesterdayEnd -and $_.Severity -ne 0})

#write the output
write-host
write-host NUMBER OF ACTIVE ALERTS YESTERDAY: ($YesterdayAlerts).Count
write-host
write-host CURRENT NUMBER OF ACTIVE ALL           ALERTS: @(get-scomalert | where {$_.ResolutionState -ne ‘255’}).count
write-host CURRENT NUMBER OF ACTIVE CRITICAL      ALERTS: @(get-scomalert | where {$_.ResolutionState -ne ‘255’ -and $_.Severity -eq ‘2’}).count  -foregroundcolor “red”
write-host CURRENT NUMBER OF ACTIVE WARNING       ALERTS: @(get-scomalert | where {$_.ResolutionState -ne ‘255’ -and $_.Severity -eq ‘1’}).count  -foregroundcolor “yellow”
write-host CURRENT NUMBER OF ACTIVE INFORMATIONAL ALERTS: @(get-scomalert | where {$_.ResolutionState -ne ‘255’ -and $_.Severity -eq ‘0’}).count
write-host
write-host
write-host TOPLIST OF YESTERDAYS ALERTS SORTED BY COUNT:

#list and sort yesterday alerts
$YesterdayAlerts | Group-Object Name |Sort -desc Count | select-Object Count, Name |Format-Table –auto
write-host

#list and sort current active alerts
write-host CURRENT ACTIVE CRITICAL ALERT LIST:  -foregroundcolor “red”
(get-scomalert | where {$_.ResolutionState -ne ‘255’ -and $_.Severity -eq ‘2’} | Group-Object Name |Sort -desc Count | select-Object Count, Name |Format-Table –auto)