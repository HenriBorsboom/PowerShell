Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False, `
        [Parameter(Mandatory=$False, Position=6)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS)

    $Jobs = @()
    
    #Switch ($ReportImmediate) {
    #    $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -ForegroundColor White, Cyan, White, Yellow }
    #}
    ForEach ($Target in $Targets) {
        #Switch ($ReportImmediate) {
        #    $False { Write-Color -Text "Starting Job for ", $Target -ForegroundColor White, Yellow }
        #}
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            #"ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            #"Both" {
            #    $Arguments = @()
            #    $Arguments = $Arguments + $Target
            #    ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
            #        $Arguments = $Arguments + $ScriptBlockArgument
            #    }
            #    $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            #$FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where-Object {$_.HasMoreData -eq "True"})
                    ForEach ($CompleteJob in $CompletedJobs) {
                        Receive-Job $CompleteJob
                    }
                }
            }
            $RunningJobs  = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    $JobResults = @()
    Switch ($ReportImmediate) {
        $False {
            ForEach ($Job in $Jobs) {
                $JobResults = $JobResults + (Receive-Job $Job)
            }
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}


$Reports = Get-ChildItem 'C:\Temp\Reports'-File
$TargetRestoreFolder = 'C:\TempRestore'

#$StartTime = Get-Date

$ScriptBlock = {
    Param ($Report)
    #For ($i = 0; $i -lt $Reports.Count; $i ++) {
        #$i | Out-File $ResumeIFile -Encoding ascii -Force    
        #Write-Progress -PercentComplete ($i / $Reports.Count * 100) -Activity ('Copying Reports - ' + ($i / $Reports.Count * 100) + '%') -ID 1
        #$ArchiveReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_ArchiveReport.txt')
        #$MissingReportFile = ('D:\Temp\CommVault\Failed_Reports\FILESERVER01_' + $Reports[$i].BaseName + '_MissingReport.txt')
        #Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' - Getting Contents of ' + $Reports[$i])
        $TargetRestoreFolder = 'C:\TempRestore'
        [String[]] $RestoreFiles = Get-Content $Report.FullName
        For ($x = 0; $x -lt $RestoreFiles.Count; $x ++) {
            #$x | Out-File $ResumeXFile -Encoding ascii -Force
            Write-Progress -PercentComplete ($x / $RestoreFiles.Count * 100) -Activity ('Copying Files - ' + ($x / $RestoreFiles.Count * 100) + '%') -ParentId 1
            Write-Host (($i + 1).ToString() + '/' + $Reports.Count.ToString() + ' | ' + ($x + 1).ToString() + '/' + $RestoreFiles.Count.ToString() + ' Processing ' + $RestoreFiles[$x] + ' - ') -NoNewline
            $RestoreFile = $RestoreFiles[$x] #.Replace('C:\Temp\', 'C:\TempRestore\')
            #If (Test-Path -LiteralPath $RestoreFile) {
                #If ((Get-Item -LiteralPath $RestoreFile).Mode -like '*l*') {
                #    #$RestoreFile | Out-File $ArchiveReportFile -Encoding ascii -Append
                #    #Write-Host 'Archived' -ForegroundColor Yellow
                #}
                #Else {
                    $RestorePath = $RestoreFile.Replace('C:\Temp', '') -split '\\'
                    For ($y = 0; $y -le ($RestorePath.Count - 2); $y ++) {
                        If (Test-Path -LiteralPath ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\'))) {
                            #folder exists
                        }
                        Else {
                            New-Item ($TargetRestoreFolder + '\' + (($RestorePath[0..$y]) -join '\')) -ItemType Directory | Out-Null
                        }
                    }
                    If (Test-Path -LiteralPath ($RestoreFile.Replace('C:\Temp', $TargetRestoreFolder))) {
                        If ((Get-ChildItem $RestoreFile).Length -gt (Get-ChildItem ($RestoreFile.Replace('C:\TempRestore', $TargetRestoreFolder))).Length) {
                            Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('C:\TempRestore', $TargetRestoreFolder)) -Force
                            Write-Host 'Newer Copied' -ForegroundColor Cyan
                        }
                        Else {
                            Write-Host 'Skipped' -ForegroundColor Green
                        }
                    }
                    Else {
                        Copy-Item -LiteralPath $RestoreFile -Destination ($RestoreFile.Replace('C:\Temp', $TargetRestoreFolder))
                        Write-Host 'Copied' -ForegroundColor Green
                    }
                #}

            #}
            #Else {
            #    #$RestoreFile | Out-File $MissingReportFile -Encoding ascii -Append
            #    Write-Host 'Missing' -ForegroundColor Red
            #}
            #Control-Stop
        }
        #0 | Out-File $ResumeXFile -Encoding ascii -Force
        Remove-Variable RestoreFiles
        [GC]::Collect()
    #}
}

Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $ScriptBlock -MaximumJobs 5 -Targets $Reports