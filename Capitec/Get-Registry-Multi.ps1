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
#Example of Use
Clear-Host
$QueryReg = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Henri\Reg'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFoler -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    $Details = @()
    Try {
        ('Invoking command on ' + $Server) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ScriptBlock {
            # Define the registry path relative to HKLM
            $keyPath = "SYSTEM\CurrentControlSet\Control\Terminal Server"

            # Open the registry key from HKEY_LOCAL_MACHINE
            $regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath)

            # Get the data type of the registry value 'fDenyTSConnections'
            $valueType = $regKey.GetValueKind("fDenyTSConnections")
            $value = $regKey.GetValue("fDenyTSConnections")
            # Output the type
            Return $valueType, $value
        }
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            ValueType = $Result[0]
            Value = $Result[1]
            Result = 'Success'
        })
        Write-Host ($Server + ": Complete") -ForegroundColor Green
        ('Complete') | Out-File $OutFile -Encoding ascii -Append
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            ValueType = $null
            Value = $null
            Result = $_
        })
        Write-Host ($Server + ": " + $_) -ForegroundColor Red
        ('Failed. ' + $_) | Out-File $OutFile -Encoding ascii -Append
    }
    $Details | Select-Object Server, ValueType, Value, Result | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
    
}
$Servers = @()
#region Servers

#endregion

Start-Jobs -ScriptBlock $QueryReg -Targets $Servers -PassTargetToScriptBlock TargetOnly -MaximumJobs 10