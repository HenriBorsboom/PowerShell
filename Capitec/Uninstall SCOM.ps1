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
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}

$SCOM = {
    Param (
        [Parameter(Mandatory=$True, Position = 1)]
        [String] $Server,
        [Parameter(Mandatory=$True, Position = 2)]
        [Object] $Credential
    )

    $SoftwarePackages = @()
    $SoftwarePackages += ,('Microsoft Monitoring Agent')
    $SoftwarePackages += ,('Configuration Manager Client')
    $OutFile = ('C:\Temp\Henri\SCOM_Uninstall\Uninstall\' + $Server + '_' + (Get-Date).ToString('yyyy_MM_dd HH_mm_ss') + '.csv')
    $Uninstalled = ('C:\Temp\Henri\SCOM_Uninstall\Uninstall\Uninstalled_' + $Server + '_' + (Get-Date).ToString('yyyy_MM_dd HH_mm_ss') + '.csv')
    Try {
        Write-Host "Getting installed software - " -NoNewline
        $CimSession = New-CimSession -ComputerName $Server -Credential $Credential
        $InstalledSoftware = Get-CimInstance -ClassName Win32_Product -CimSession $CimSession
        $InstalledSoftware | Sort-Object Name | Select Name, Caption, Version | Export-Csv $OutFile -Encoding ASCII -Force -Delimiter ',' -NoTypeInformation
        ForEach ($SoftwarePackage in $SoftwarePackages) {
            If ($InstalledSoftware.Name -contains $SoftwarePackage) {
                Write-Host ($Server + ": " + $SoftwarePackage + " Installed")
                $Output = Invoke-CimMethod -InputObject ($InstalledSoftware | Where-Object Name -eq $SoftwarePackage) -MethodName Uninstall -CimSession $CimSession
                $Details = @(New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Software = $SoftwarePackage
                    Installed = $True
                    UninstallCode = $Output.ReturnCode
                })
            }
            Else {
                $Details = @(New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Software = $SoftwarePackage
                    Installed = $False
                    UninstallCode = $null
                })
            }
            Write-Host "Complete" -ForegroundColor Green
            $Details | Select-Object Server, Software, Installed, UninstallCode | Export-Csv $Uninstalled -Encoding ASCII -Append -Delimiter ',' -NoTypeInformation
        }
    }
    Catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
        $Details = @(New-Object -TypeName PSObject -Property @{
            Server = $Server
            Software = $null
            Installed = $null
            UninstallCode = $_.Exception.Message
        })
        $Details | Select-Object Server, Software, Installed, UninstallCode | Export-Csv $Uninstalled -Encoding ASCII -Append -Delimiter ',' -NoTypeInformation
    }
}
$Servers = Get-Content .\servers.txt
$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $SCOM -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10