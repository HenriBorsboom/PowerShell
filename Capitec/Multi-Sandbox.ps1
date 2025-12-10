Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; sleep 1 }
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both","None")]
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
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS
    )

    $Jobs = @()
    
    For ($Index = 0; $Index -lt $Targets.Count; $Index ++) {
        $Target = $Targets[$index]
        Write-Host (($Index + 1).ToString() + '/' + $Targets.Count.ToString() + ' - Starting Job for ' + $Target)
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)
            }
            "None" { $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock ) }
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $ActiveJob = Get-Job | Where State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where State -eq 'Running' | Receive-Job
                }
                $False {
                    If ($Null -ne $ActiveJob) {
                        Receive-Job $ActiveJob | Remove-Job $ActiveJob
                    }
                }
            }
            $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    #$JobResults = @()
    #Switch ($ReportImmediate) {
    #    $False {
    #        ForEach ($Job in $Jobs) {
    #            $JobResults = $JobResults + (Receive-Job $Job)
    #        }
    #    }
    #}
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}

$SB = {
    Param ($JobIndex)
    For ($i = 0; $i -lt 5; $i ++) {
        Write-Host ($JobIndex.ToString() + ": Waiting")
        Start-Sleep -Seconds 1
    }
    Write-Host ($JobIndex.ToString() + ': Complete')
}

Start-Jobs -PassTargetToScriptBlock TargetOnly -ScriptBlock $SB -Targets @(1..5) -MaximumJobs 5 -ReportImmediate