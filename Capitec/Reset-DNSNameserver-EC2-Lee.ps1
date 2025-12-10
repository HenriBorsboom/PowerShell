Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; Start-Sleep -Seconds 1 }
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
            $ActiveJob = Get-Job | Where-Object State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where-Object State -eq 'Running' | Receive-Job
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
Function Get-DomainServers {
    $LogonDate = (Get-Date).AddMonths(-2)
    $Servers = Get-ADComputer -Filter {Enabled -eq $True -and LastLogonDate -gt $LogonDate -and OperatingSystem -like '*server*'} -Properties LastLogonDate, Enabled, OperatingSystem
    Return $Servers.Name
}
Function Get-CSVData {
    $CSVs = get-childitem 'C:\Temp\Henri\ResetDNS3\*.csv'
    $Details = @()
    ForEach ($CSV in $CSVs) {
        $Data = Import-Csv $CSV.FullName
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Data.Server
            Result = $Data.Result
        })
        Remove-Variable Data
    }
    $Details | Select-Object Server, Result | Out-GridView
}
Clear-Host
$ResetEC2DNS = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    
    $ErroractionPreference = 'Stop'
    $OutputFolder = 'C:\Temp\Lee\DNSUpdates\EC2'
    If (Test-Path $OutputFolder) {

    }
    Else {
        New-Item $OutputFolder -ItemType Directory | Out-Null
    }
    $OutFile = ($OutputFolder +'\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ($OutputFolder + '\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')
    $Details = @()
    Try {
        ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -Credential $Credential -ScriptBlock {
            Try {
                [Object[]] $AdapterGUIDs = Get-NetAdapter | Select-Object InterfaceGuid
                ForEach ($AdapterGUID in $AdapterGUIDs) {
                    Set-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid) -Name NameServer -Value "" -ErrorAction Stop
                }
                Return $True
            }
            Catch {
                Return $_.Exception.Message
            }
        }
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            Result = $Result
        })
        If ($Details.Result -eq $True) {            
            Write-Host ($Server + ": Complete") -ForegroundColor Green
            ('Complete') | Out-File $OutFile -Encoding ascii -Append
        }
        Else {
            Write-Host ($Server + ": " + $Details.Result) -ForegroundColor Yellow
        }
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            Result = $_.Exception.Message
        })
        Write-Host ($Server + ": " + $_.Exception.Message) -ForegroundColor Red
        ('Failed. ' + $_.Exception.Message) | Out-File $OutFile -Encoding ascii -Append
    }
    $Params = @("Server", "Result")
    $Details | Select-Object $Params | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
}
#$Servers = Get-DomainServers
#$Credential = Get-Credential

$SBArgs = @($Credential)
#$Servers = AWSDEV; Start-Jobs -ScriptBlock $ResetEC2DNS -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
#$Servers = AWSINT; Start-Jobs -ScriptBlock $ResetEC2DNS -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
#$Servers = AWSQA; Start-Jobs -ScriptBlock $ResetEC2DNS -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = AWSPRD; Start-Jobs -ScriptBlock $ResetEC2DNS -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10