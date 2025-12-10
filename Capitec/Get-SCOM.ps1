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
$SB = {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server,
        [Parameter(Mandatory=$True, Position=2)]
        [Object] $Credential
    )

    $ErrorActionPreference = 'Stop'

    $Details = @()
    Try {
        $Product = Get-WMIObject -query ('select Caption from win32_product where name = "Microsoft Monitoring Agent"') -ComputerName $Server -Credential $Credential
        [Object[]] $Services = Get-WMIObject -query ('select * from win32_service where name = "HealthService"') -ComputerName $Server -Credential $Credential
        If ($Null -eq $Product -and $Null -eq $Services) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Installed = $False
                ServiceInstalled = $False
                ServiceRunning = $False
                Status = 'Not installed'
            })
        }
        Else {
            ForEach ($Service in $Services) {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Installed = $Product.Caption
                    ServiceInstalled = $Service.Name
                    ServiceRunning = $Service.State
                    Status = 'Installed'
                })
            }
        }
        $Product = Get-WMIObject -query "SELECT Caption FROM Win32_Product WHERE Caption LIKE '%configuration%'" -ComputerName $Server -Credential $Credential
        [Object[]] $Services = Get-WMIObject -query ('select * from win32_service where name = "ccmexec"') -ComputerName $Server -Credential $Credential
        If ($Null -eq $Product -and $Null -eq $Services) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Server
                Installed = $False
                ServiceInstalled = $False
                ServiceRunning = $False
                Status = 'Not installed'
            })
        }
        Else {
            ForEach ($Service in $Services) {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    Server = $Server
                    Installed = $Product.Caption
                    ServiceInstalled = $Service.Name
                    ServiceRunning = $Service.State
                    Status = 'Installed'
                })
            }
        }
        Write-Host ($env:Computername + ' - Complete') -ForegroundColor Green
    }
    Catch {
        Write-Host ($env:Computername + ' - ' + $_.Exception.Message) -ForegroundColor Red
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            Installed = $Null
            ServiceInstalled = $Null
            ServiceRunning = $Null
            Status = $_
        })
    }
    $Details | Select-Object Server, Installed, ServiceInstalled, ServiceRunning, Status | Export-CSV ('C:\Temp\Henri\SCOM\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '__.csv') -Delimiter ';' -NoTypeInformation
}
$LogonDate = (Get-Date).AddMonths(-2)
$Servers = (Get-ADComputer -Filter {Enabled -eq $True -and OperatingSystem -like '*server*' -and LastLogonDate -gt $LogonDate} -Properties OperatingSystem, LastLogonDate | Select Name).Name
$Servers | Export-Csv 'C:\Temp\Henri\AD_SCOM_SCCM_SERVERS-2025-06-10.csv' -Delimiter ';' -NoTypeInformation
#$Credential = Get-Credential
$SBArgs = @($Credential)
Start-Jobs -ScriptBlock $SB -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
