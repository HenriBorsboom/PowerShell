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
Function Start-Thread {
    Param (
        [Parameter(Mandatory=$False, Position=0)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS, `
        [Parameter(Mandatory=$True, Position=1)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)][ValidateSet("TargetOnly","ArgumentsOnly","Both")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False)

    $Jobs               = @()
    
    Switch ($ReportImmediate) {
        $True { Write-Color -Text "Starting Jobs for ", $Targets.Count, " targets.", " Please wait for the results." -Color White, Cyan, White, Yellow }
    }
    ForEach ($Target in $Targets) {
        Switch ($ReportImmediate) {
            $False { Write-Color -Text "Starting Job for ", $Target -Color White, Yellow }
        }
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
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
    ForEach ($Job in $Jobs) {
        Receive-Job $Job
    }
    Get-Job | Wait-Job | Remove-Job
}

Import-Module ActiveDirectory
Clear-Host

$DomainControllers = (Get-ADComputer -SearchBase "OU=Domain Controllers,DC=sysproza,DC=net" -Filter *).Name
$DomainControllers = $DomainControllers | Sort
$User              = Read-Host -Prompt “Please enter a user name”
$Duration          = Read-Host "Duration (minutes)"
$ScriptBlock = {
    Param ($DC, $Duration, $User); 
    Get-WinEvent -ComputerName $DC -FilterHashtable @{
        logname="Security"; 
        StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;
        } `
    -MaxEvents 10 `
    -Oldest `
    -Force `
    -ErrorAction SilentlyContinue `
    | Where Message -like "*$User*" `
    | Select MachineName, TimeCreated, ID, Message `
    | Format-Table -AutoSize -Wrap
}

Start-Thread -ScriptBlock $ScriptBlock -PassTargetToScriptBlock Both -ScriptBlockArguments $Duration, $User -Targets $DomainControllers -ReportImmediate
Unlock-ADAccount -Identity $User -Verbose