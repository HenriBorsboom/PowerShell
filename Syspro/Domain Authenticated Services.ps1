<#
    .Synopsis
        Execute multiple Start-Job commands and throttle them
    .Description
        Execute multiple Start-Job commands and throttle them
        according to specified maximum
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock TargetOnly -ReportImmediate -MaximumJobs 5
        Executes the scriptblock in $SB1 against 30 targets, throttled to 5 concurrent jobs
        and passing only the current target to the scriptblock as a parameter and reporting results of completed jobs immediately
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock TargetOnly -ReportImmediate
        Executes the scriptblock in $SB1 against 30 targets and passing only the current target to the 
        scriptblock as a parameter and reporting results of completed jobs immediately
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock ArgumentsOnly -ScriptBlockArguments $SBArgs -ReportImmediate
        Executes the scriptblock in $SB1 against 30 targets and passing only $SBArgs arguments to the 
        scriptblock as a parameters and reporting results of completed jobs immediately
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock Both -ScriptBlockArguments $SBArgs -ReportImmediate
        Executes the scriptblock in $SB1 against 30 targets and passing the target and $SBArgs arguments to the 
        scriptblock as a parameters and reporting results of completed jobs immediately. The Target MUST be the first
        required parameter in the scriptblock
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock TargetOnly
        Executes the scriptblock in $SB1 against 30 targets and passing only the current target to the 
        scriptblock as a parameter returning results upon completion of all jobs
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock ArgumentsOnly -ScriptBlockArguments $SBArgs
        Executes the scriptblock in $SB1 against 30 targets and passing only $SBArgs arguments to the 
        scriptblock as a parameters and returning results upon completion of all jobs
    .Example
        Start-Jobs -ScriptBlock $SB1 -Targets @(1..30) -PassTargetToScriptBlock Both -ScriptBlockArguments $SBArgs
        Executes the scriptblock in $SB1 against 30 targets and passing the target and $SBArgs arguments to the 
        scriptblock as a parameters and returning results upon completion of all jobs
        required parameter in the scriptblock
    .Parameter ScriptBlock
        The scriptblock that needs to be executed per job
    .Inputs
        [ScriptBlock]
    .Parameter ScriptBlockArguments
        Arguments to be passed to the scriptblock
    .Inputs
        [Object[]]
    .Parameter Targets
        The targets against which the scriptblock will execute
    .Inputs
        [Object[]]
    .Parameter ReportImmediate
        Report immediately if upon job completion. Default is FALSE
    .Inputs
        [Switch]
    .Parameter MaximumJobs
        Maximum number of jobs to execute simultaneously. Default is number of logical processors
    .Inputs
        [Switch]
    .OutPuts
        [String[]]
    .Notes
        NAME:  Start-Jobs
        AUTHOR: Henri Borsboom
        LASTEDIT: 04/10/2016
        KEYWORDS: Multiple Jobs, Threading, Multi-thread
    .Link
        https://www.linkedin.com/pulse/powershell-managing-multiple-start-jobs-henri-borsboom
        #Requires -Version 4.0
#>
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

    Function Write-Color {
        Param(
            [Parameter(Mandatory = $True  , Position = 1)]
            [String[]]       $Text, `
            [Parameter(Mandatory = $True  , Position = 2)]
            [ConsoleColor[]] $Color, `
            [Parameter(Mandatory = $False , Position = 3)]
            [Switch]           $NoNewLine)

        $ErrorActionPreference = "Stop"
        Try {
            If ($Text.Count -ne $Color.Count) {
                Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
                Throw
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
            }
            Switch ($NoNewLine){
                $True  { Write-Host -NoNewline }
                $False { Write-Host }
            }
        }
        Catch { }
    }
    $Jobs = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    For ($I = 0; $I -lt $Targets.Count; $I ++) {
    #ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text ($I + 1),"/",$Targets.Count, " - Starting Job for ", $Targets[$I] -Color Cyan, Cyan, Cyan, White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Targets[$I])}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Targets[$I]
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)}
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $FinishedJobs = Wait-Job -Job $Jobs -Any
            Switch ($ReportImmediate) {
                $True {
                    $CompletedJobs = @($Jobs | Where {$_.HasMoreData -eq "True"})
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
<#Clear-Host
$SB1 = {
    Param ($Counter)

    For ($i = 0; $i -lt 2; $i ++) {
        Sleep 1
    }
    Write-Host "$Counter - Complete" -ForegroundColor Green
}
$SBArgs = @(1)
#>
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $Color.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { }
}
    
Function Get-DomainComputers {
    Param (
        [Parameter(Mandatory = $True,  Position = 1)]
        [String] $Domain)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "Computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}
$Computers = Get-DomainComputers -Domain "DOMAIN3"
New-Item -Path "$env:TEMP\Services" -ItemType Directory | Out-Null
$SB = {
    Param ($Computer)

    Function Write-Color {
        Param(
            [Parameter(Mandatory = $True  , Position = 1)]
            [String[]]       $Text, `
            [Parameter(Mandatory = $True  , Position = 2)]
            [ConsoleColor[]] $Color, `
            [Parameter(Mandatory = $False , Position = 3)]
            [Switch]           $NoNewLine)

        $ErrorActionPreference = "Stop"
        Try {
            If ($Text.Count -ne $Color.Count) {
                Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
                Throw
            }
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
                Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
            }
            Switch ($NoNewLine){
                $True  { Write-Host -NoNewline }
                $False { Write-Host }
            }
        }
        Catch { }
    }
    Function Test-Online {
        Param (
            [Parameter(Mandatory=$True,  Position=1)]
            [String] $Computer)

        If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
            Return $True
        }
        Else {
            Return $False
        }
    }
    Function Get-Services {
        Param (
            [Parameter(Mandatory=$True,  Position=1)]
            [String] $Computer)

        Write-Color -Text "Checking that ", $Computer, " is online - " -Color White, Yellow, White -NoNewLine
        If ((Test-Online -Computer $Computer) -eq $True) {
            Write-Color -Text "Complete" -Color Green
            $DomainServices = @()
            Try {
                Write-Color -Text "Getting Services on ", $Computer, " - " -Color White, Yellow, White -NoNewLine
                If ($Computer -eq $env:COMPUTERNAME) { $ComputerServices = Get-WmiObject -Class "Win32_Service" -Property "StartName", "Name", "DisplayName" -ThrottleLimit 10 -ErrorAction Stop }
                Else { $ComputerServices = Get-WmiObject -Class "Win32_Service" -Property "StartName", "Name", "DisplayName" -ComputerName $Computer -ErrorAction Stop }
                Write-Color "Complete" -Color Green
        
                Write-Color -Text "Processing Services on ", $Computer, " - " -Color White, Yellow, White -NoNewLine
                ForEach ($Service in $ComputerServices) {
                    If (
                        $Service.StartName -ne "LocalSystem" -and 
                        $Service.StartName -ne $Null -and 
                        $Service.StartName -ne "" -and
                        $Service.StartName -notlike "NT Authority\*" -and
                        $Service.StartName -notlike "NT AUTHORITY\*" -and
                        $Service.StartName -notlike "NT Service\*") {
                        $LogonService = New-Object PSObject -Property @{
                            ComputerName = $Computer
                            ServiceName  = $Service.Name
                            DisplayName  = $Service.DisplayName
                            Logon        = $Service.StartName
                        }
                    $DomainServices = $DomainServices + $LogonService
                    }
                }
                Write-Color -Text "Complete" -Color Green
                If ($DomainServices.count -ne 0) {
                    Return $DomainServices
                }
                Else { 
                    Return $False
                }
            }
            Catch {
                Write-Color -Text "Failed", " - ", $_ -Color Red, White, Red
                Return $False
            } 
        }
        Else {
            Write-Color -Text "Failed" -Color Red
            Return $False
        }
    }

    $DisplayOptions = @("Computername", "ServiceName", "DisplayName", "Logon")
    

    $AllServices = @()
    $ComputerDomainServices = Get-Services -Computer $Computer
    If ($ComputerDomainServices -ne $False) {
        $AllServices = $AllServices + $ComputerDomainServices
        $AllServices | Select $DisplayOptions | Export-CSV -Path "$env:TEMP\Services\$Computer.csv" -Force -NoClobber -Encoding ASCII -Delimiter "," -NoTypeInformation 
    }
}
Write-Color -Text "Total Computers Found: ", $Computers.Count -Color White, Yellow
Start-Jobs -ScriptBlock $SB -Targets $Computers -PassTargetToScriptBlock TargetOnly -MaximumJobs 10
Write-Color -Text "Combining output of computers - " -Color White -NoNewLine
$AllServicesFile = "$env:TEMP\AllServices.csv"
'"ComputerName","ServiceName","DisplayName","Logon"' | Out-File $AllServicesFile -Encoding ascii -Force -NoClobber
ForEach ($CSV in (Get-ChildItem "*.csv" -Path "$env:TEMP\Services")) {
    $CSVContent = Get-Content $CSV.FullName
    For ($i = 1; $i -lt $CSVContent.Count; $i ++) { $CSVContent[$i] | Out-File $AllServicesFile -Encoding ascii -Append -NoClobber }
}
Get-ChildItem *.csv -Path "$env:TEMP\Services" | Remove-Item -Confirm:$false
Remove-Item "$env:TEMP\Services" -Confirm:$false
Write-Color -Text "Complete" -Color Green
Notepad $AllServicesFile