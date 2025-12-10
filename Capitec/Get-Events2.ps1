#Variables
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
    For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
        Write-Host ("Getting Logs from " + $ActiveLogs[$LogI].LogName + " - ") -NoNewLine
        If ($ExcludeLog.Count -gt 0) {
            If (!$ExcludeLog.Contains(($ActiveLogs[$LogI].LogName -split '/')[0])) {
                Switch ($SuppressInfo) {
                    $True {
                        $HashFilter = {
                            LogName = $ActiveLogs[$LogI].LogName
                            StartTime = $StartDate
                            EndTime = $EndDate
                            Level = 1,2,3
                        }
                    }
                    $False {
                        $HashFilter = {
                            LogName = $ActiveLogs[$LogI].LogName
                            StartTime = $StartDate
                            EndTime = $EndDate
                        }
                    }
                }
                $LogEvents = Get-WinEvent -FilterHashTable $HashFilter -ErrorAction SilentlyContinue
                Write-Host ($LogEvents.Count.ToString() + ' found')
                If ($LogEvents.Count -gt 0) {
                    ForEach ($Event in $LogEvents) {
                        $AllEvents += ,(New-Object -TypeName PSObject -Property @{
                            LogName = $Event.ProviderName
                            TimeCreated = $Event.TimeCreated
                            ID = $Event.Id
                            LevelDisplayName = $Event.LevelDisplayName
                            Level = $Event.Level
                            Message = $Event.Message
                        })
                    }
                }
                #$AllEvents += ,($LogEvents)
                $EventCount += $LogEvents.Count
                $LogEvents = 0
            }
        }
        Else {
            Switch ($SuppressInfo) {
                $True {
                    $HashFilter = {
                        LogName = $ActiveLogs[$LogI].LogName
                        StartTime = $StartDate
                        EndTime = $EndDate
                        Level = 1,2,3
                    }
                }
                $False {
                    $HashFilter = {
                        LogName = $ActiveLogs[$LogI].LogName
                        StartTime = $StartDate
                        EndTime = $EndDate
                    }
                }
            }
            $LogEvents = Get-WinEvent -FilterHashTable $HashFilter -ErrorAction SilentlyContinue
            Write-Host ($LogEvents.Count.ToString() + ' found')
            If ($LogEvents.Count -gt 0) {
                ForEach ($Event in $LogEvents) {
                    $AllEvents += ,(New-Object -TypeName PSObject -Property @{
                        LogName = $Event.ProviderName
                        TimeCreated = $Event.TimeCreated
                        ID = $Event.Id
                        LevelDisplayName = $Event.LevelDisplayName
                        Level = $Event.Level
                        Message = $Event.Message
                    })
                }
            }
            #$AllEvents += ,($LogEvents)
            $EventCount += $LogEvents.Count
            $LogEvents = 0
        }
    }
    Write-Host ("Total events recorded: " + $EventCount.ToString())

    $OutFile = ($Env:TEMP + '\Events_' + '{0:yyyy-mm-dd_HH.mm.ss}' -f (Get-Date) + '.txt')
    $AllEvents | Sort-Object TimeCreated | Select-Object LogName, TimeCreated, ID, LevelDisplayName, Level, Message | Format-List | Out-File $OutFile -Force -Encoding ascii
    #$AllEvents | Sort-Object TimeCreated | Select-Object LogName, TimeCreated, ID, LevelDisplayName, Level, Message | Format-List
    Write-Host ("Events saved to: ")
    Write-Host ("  " + $OutFile)
    Notepad $OutFile
    #Return $AllEvents
}

Get-Events -StartDate '2024/03/27 07:10' -EndDate '2024/03/27 07:18' -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering-NetFt', 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders'
#Get-Events -StartDate '2024/03/28 08:53' -EndDate '2024/03/28 09:03' -SuppressInfo -ExcludeLog 'Microsoft-Windows-FailoverClustering-NetFt', 'Microsoft-Windows-FailoverClustering', 'Microsoft-Windows-KnownFolders', 'Microsoft-Windows-PowerShell', 'Microsoft-Windows-Diagnosis-PLA', 'Microsoft-Windows-KnownFolders'