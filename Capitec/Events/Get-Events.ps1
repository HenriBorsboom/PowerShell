<#
.SYNOPSIS
    Retrieves Windows Event Logs within a specified time range, with options to filter by severity and exclude specific logs.

.DESCRIPTION
    This script scans all active Windows Event Logs (those with records) and collects events between a given StartDate and EndDate.
    You can choose to suppress informational events (Level 4) and exclude specific logs from the search.
    The results are saved to a timestamped text file and opened in Notepad.

.PARAMETER StartDate
    The beginning of the time range for event collection. Must be a valid DateTime.

.PARAMETER EndDate
    The end of the time range for event collection. Must be a valid DateTime.

.PARAMETER SuppressInfo
    Optional switch to exclude informational events (Level 4). Only Critical (1), Error (2), and Warning (3) events will be included.

.PARAMETER ExcludeLog
    Optional array of log names to exclude from the search. Partial names (before '/') are matched.

.OUTPUTS
    A text file containing formatted event data, saved in the user's TEMP directory.

.EXAMPLE
    Get-Events -StartDate '2025/09/26 07:00' -EndDate '2025/09/26 08:00'
    Retrieves all events from all logs within the specified time range.

.EXAMPLE
    Get-Events -StartDate '2025/09/26 07:00' -EndDate '2025/09/26 08:00' -SuppressInfo
    Retrieves only warnings, errors, and critical events.

.EXAMPLE
    Get-Events -StartDate '2025/09/26 07:00' -EndDate '2025/09/26 08:00' -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders'
    Retrieves filtered events while excluding specified logs.

.NOTES
    Author: Henri Borsboom
    Last Updated: 2025-09-26
#>

$ErrorActionPreference = 'SilentlyContinue'
Function Get-Events {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [DateTime] $StartDate, `
        [Parameter(Mandatory=$True, Position=2)]
        [DateTime] $EndDate, `
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $SuppressInfo,
        [Parameter(Mandatory=$False, Position=4)]
        [String[]] $ExcludeLog
    )

    Write-Host "Getting All System logs with records - " -NoNewline
    $ActiveLogs = Get-WinEvent -ListLog * | Where-Object {$_.RecordCount -gt 0}
    Write-Host ($ActiveLogs.Count.ToString() + ' logs found')

    $AllEvents = @()
    $EventCount = 0
    Switch ($SuppressInfo) {
        $True {
            For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
                Write-Host ("Getting Logs from " + $ActiveLogs[$LogI].LogName + " - ") -NoNewLine
                If ($ExcludeLog.Count -gt 0) {
                    If (!$ExcludeLog.Contains(($ActiveLogs[$LogI].LogName -split '/')[0])) {
                        $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate; Level = 1,2,3} -ErrorAction SilentlyContinue
                        Write-Host ($LogEvents.Count.ToString() + ' found')
                        If ($LogEvents.Count -gt 0) {
                            ForEach ($LogEvent in $LogEvents) {
                                $AllEvents += ,(New-Object -TypeName PSObject -Property @{
                                    LogName = $LogEvent.ProviderName
                                    TimeCreated = $LogEvent.TimeCreated
                                    ID = $LogEvent.Id
                                    LevelDisplayName = $LogEvent.LevelDisplayName
                                    Level = $LogEvent.Level
                                    Message = $LogEvent.Message
                                })
                            }
                        }
                        $EventCount += $LogEvents.Count
                        $LogEvents = 0
                    }
                }
            }
            Write-Host ("Total events recorded: " + $EventCount.ToString())
        }
        $False {
            For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
                Write-Host ("Getting Logs from " + $ActiveLogs[$LogI].LogName + " - ") -NoNewLine
                If ($ExcludeLog.Count -gt 0) {
                    If (!$ExcludeLog.Contains(($ActiveLogs[$LogI].LogName -split '/')[0])) {
                        $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate} -ErrorAction SilentlyContinue
                        Write-Host ($LogEvents.Count.ToString() + ' found')
                        If ($LogEvents.Count -gt 0) {
                            ForEach ($LogEvent in $LogEvents) {
                                $AllEvents += ,(New-Object -TypeName PSObject -Property @{
                                    LogName = $LogEvent.ProviderName
                                    TimeCreated = $LogEvent.TimeCreated
                                    ID = $LogEvent.Id
                                    LevelDisplayName = $LogEvent.LevelDisplayName
                                    Level = $LogEvent.Level
                                    Message = $LogEvent.Message
                                })
                            }
                        }
                        $EventCount += $LogEvents.Count
                        $LogEvents = 0
                    }
                }
            }
            Write-Host ("Total events recorded: " + $EventCount.ToString())
        }
    }

    $OutFile = ($Env:TEMP + '\Events_' + '{0:yyyy-MM-dd_HH.mm.ss}' -f (Get-Date) + '.txt')
    $AllEvents | Sort-Object TimeCreated | Select-Object LogName, TimeCreated, ID, LevelDisplayName, Level, Message | Format-List | Out-File $OutFile -Force -Encoding ascii
    Write-Host ("Events saved to: ")
    Write-Host ("  " + $OutFile)
    Notepad $OutFile
    #Return $AllEvents
}

$StartTime = '2025/10/01 06:00'
$EndTime   = '2025/10/01 07:00'

# Get-Events -StartDate $StartTime -EndDate $EndTime -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering-NetFt', 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders'
Get-Events -StartDate $StartTime -EndDate $EndTime -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering-NetFt', 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders'
#Get-Events -StartDate $StartTime -EndDate $EndTime -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering-NetFt', 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders', 'Microsoft-Windows-PowerShell', 'Microsoft-Windows-Diagnosis-PLA', 'Microsoft-Windows-KnownFolders'