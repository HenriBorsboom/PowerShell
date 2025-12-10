Clear-Host
Set-StrictMode -Version 2
Function Get-Logs {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [DateTime] $StartTime = "2022/11/15 08:30:00",
        [Parameter(Mandatory=$False, Position=2)]
        [DateTime] $EndTime   = "2022/11/15 08:45:00",
        [Parameter(Mandatory=$False, Position=3)]
        [Switch] $SkipSecurity = $False,
        [Parameter(Mandatory=$False, Position=4)]
        [Switch] $CriticalWarningErrorOnly = $True,
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $PrimaryLogs = $False,
        [Parameter(Mandatory=$False, Position=6)]
        [Int]    $Level,
        [Parameter(Mandatory=$False, Position=7)]
        [String] $Log
        )

<#
Name	Value
Verbose	5
Informational	4
Warning	3
Error	2
Critical	1
LogAlways	0
#>


    If ($CriticalWarningErrorOnly -eq $True) {$LogLevel = 1,2,3}
    If ($Level -eq 0) {$LogLevel = $null}

    Write-Host "Getting logs - " -NoNewline
    If ($PrimaryLogs -eq $True) {
        $Logs = @("Application", "System")
    }
    ElseIf ($Log -ne '') {
        $Logs = @($Log)
    }
    Else {
        $Logs = (Get-WinEvent -ListLog * | Where-Object {$_.RecordCount -gt 0}).LogName
    }
    Write-Host ($Logs.Count.ToString() + " found") -ForegroundColor Cyan
    $Events = @()
    ForEach ($Log in $Logs) {
        Write-Host ("Processing " + $Log + " - ") -NoNewline
                    
        Switch ($SkipSecurity) {
            $True {
                If ($Log -eq 'Security') {
                    Write-Host "Skipping" -ForegroundColor Yellow
                    Continue
                }
                Else {
                    Try {
                        If ($null -eq $LogLevel) {
                            $LogEvents = ,(Get-WinEvent -FilterHashtable @{ 
                                Logname= $Log; 
                                StartTime=$StartTime;
                                EndTime=$EndTime} -ErrorAction Stop | Select-Object {$_.LogName, $_.ProviderName, $_.TimeCreated, $_.ID, $_.LevelDisplayName, $_.Message})
                        }
                        Else {
                            $LogEvents = ,(Get-WinEvent -FilterHashtable @{ 
                                Logname= $Log; 
                                StartTime=$StartTime;
                                EndTime=$EndTime;
                                Level=1,2,3 } -ErrorAction Stop | Select-Object {$_.LogName, $_.ProviderName, $_.TimeCreated, $_.ID, $_.LevelDisplayName, $_.Message})
                        }
                        ForEach ($LogEntry in $LogEvents[0]) {
                            $Events +=, (New-Object -TypeName PSObject -Property @{
                                LogName = $LogEntry.LogName
                                ProviderName = $LogEntry.ProviderName
                                TimeCreated = $LogEntry.TimeCreated
                                ID = $LogEntry.ID
                                LevelDisplayName = $LogEntry.LevelDisplayName
                                Message = $LogEntry.Message
                            })
                        
                        }
                        Write-Host "Complete" -ForegroundColor Green
                    }
                    Catch {
                        Write-Host $_ -ForegroundColor Yellow
                    }
                    
                }
            }
            $False {
                Try {
                    If ($null -eq $LogLevel) {
                            $LogEvents = ,(Get-WinEvent -FilterHashtable @{ 
                                Logname= $Log; 
                                StartTime=$StartTime;
                                EndTime=$EndTime} -ErrorAction Stop | Select-Object {$_.LogName, $_.ProviderName, $_.TimeCreated, $_.ID, $_.LevelDisplayName, $_.Message})
                        }
                        Else {
                            $LogEvents = ,(Get-WinEvent -FilterHashtable @{ 
                                Logname= $Log; 
                                StartTime=$StartTime;
                                EndTime=$EndTime;
                                Level=1,2,3 } -ErrorAction Stop | Select-Object {$_.LogName, $_.ProviderName, $_.TimeCreated, $_.ID, $_.LevelDisplayName, $_.Message})
                        }
                        ForEach ($LogEntry in $LogEvents[0]) {
                        $Events  +=, (New-Object -TypeName PSObject -Property @{
                            LogName = $LogEntry.LogName
                            ProviderName = $LogEntry.ProviderName
                            TimeCreated = $LogEntry.TimeCreated
                            ID = $LogEntry.ID
                            LevelDisplayName = $LogEntry.LevelDisplayName
                            Message = $LogEntry.Message
                        })
                        
                    }
                    Write-Host "Complete" -ForegroundColor Green
                }
                Catch {
                    Write-Host $_ -ForegroundColor Yellow
                }
            }
        }
        
    }
    Return $Events | Sort-Object {$_.TimeCreated} | Select-Object {$_.TimeCreated, $_.LogName, $_.ProviderName, $_.ID, $_.LevelDisplayName, $_.Message}
}
#Get-Logs | Out-GridView
#Get-Logs -SkipSecurity:$False -CriticalWarningErrorOnly:$false -PrimaryLogs:$false
Get-Logs -SkipSecurity:$True -CriticalWarningErrorOnly:$false -PrimaryLogs:$false | Out-GridView
