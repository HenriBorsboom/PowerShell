Function Start-MultiThreadJob {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock)
    
    $SleepTimer = 1
    $GetChildItemJob = Start-Job -ArgumentList $ScriptBlockArguments, $ScriptBlock -ScriptBlock {Param($ScriptBlockArguments); Invoke-Expression $ScriptBlock} -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Sleep 3
        $SleepTimer ++
    }
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}
Clear-Host

#region Domain Controllers
$DCS = @(
    "SYSPRO-DCVM", `
    "SYSJHBDC", `
    "SYSCTDC", `
    "SYSDBNDC", `
    "SYSPRDDCINFRA1")
#endregion
#region Variables
$User = Read-Host -Prompt “Please enter a user name”
$Duration = Read-Host "Duration (minutes)"
Write-Host "Collecting Information"
#endregion
#region Start Jobs
$SYSPRODCVMJob          = Start-Job -Name "SYSPRODCVM"     -ArgumentList "SYSPRO-DCVM", $Duration, $User -ScriptBlock {Param ($DC, $Duration, $User); Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Where Message -like "*$User*" | Select MachineName, TimeCreated, ID, Message | Format-Table -AutoSize -Wrap}
$SYSJHBDCJob            = Start-Job -Name "SYSJHBDC"       -ArgumentList "SYSJHBDC", $Duration, $User -ScriptBlock {Param ($DC, $Duration, $User); Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Where Message -like "*$User*" | Select MachineName, TimeCreated, ID, Message | Format-Table -AutoSize -Wrap}
$SYSCTDCJob             = Start-Job -Name "SYSCTDC"        -ArgumentList "SYSCTDC", $Duration, $User -ScriptBlock {Param ($DC, $Duration, $User); Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Where Message -like "*$User*" | Select MachineName, TimeCreated, ID, Message | Format-Table -AutoSize -Wrap}
$SYSDBNDCJob            = Start-Job -Name "SYSDBNDC"       -ArgumentList "SYSDBNDC", $Duration, $User -ScriptBlock {Param ($DC, $Duration, $User); Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Where Message -like "*$User*" | Select MachineName, TimeCreated, ID, Message | Format-Table -AutoSize -Wrap}
$SYSPRDDCINFRA1Job      = Start-Job -Name "SYSPRDDCINFRA1" -ArgumentList "SYSPRDDCINFRA1", $Duration, $User -ScriptBlock {Param ($DC, $Duration, $User); Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Where Message -like "*$User*" | Select MachineName, TimeCreated, ID, Message | Format-Table -AutoSize -Wrap}
#endregion
#region Job State
$SYSPRODCVMJobState     = Get-Job $SYSPRODCVMJob.Id
$SYSJHBDCJobState       = Get-Job $SYSJHBDCJob.Id
$SYSCTDCJobState        = Get-Job $SYSCTDCJob.Id
$SYSDBNDCJobState       = Get-Job $SYSDBNDCJob.Id
$SYSPRDDCINFRA1JobState = Get-Job $SYSPRDDCINFRA1Job.Id
#endregion
#region SYSPRODCVM
While (($SYSPRODCVMJobState.State -eq "Running")) {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    Sleep 1
}
Receive-Job -Job $SYSPRODCVMJob
Remove-Job -Job $SYSPRODCVMJob
#endregion
#region SYSJHBDC
While (($SYSJHBDCJobState.State -eq "Running")) {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    Sleep 1
}
Receive-Job -Job $SYSJHBDCJob
Remove-Job -Job $SYSJHBDCJob
#endregion
#region SYSCTDC
While (($SYSCTDCJobState.State -eq "Running")) {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    Sleep 1
}
Receive-Job -Job $SYSCTDCJob
Remove-Job -Job $SYSCTDCJob
#endregion
#region SYSDBNDC
While (($SYSDBNDCJobState.State -eq "Running")) {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    Sleep 1
}
Receive-Job -Job $SYSDBNDCJob
Remove-Job -Job $SYSDBNDCJob
#endregion
#region SYSPRDDCINFRA1
While (($SYSPRDDCINFRA1JobState.State -eq "Running")) {
    Write-Host "." -NoNewline -ForegroundColor Cyan
    Sleep 1
}
Receive-Job -Job $SYSPRDDCINFRA1Job
Remove-Job -Job $SYSPRDDCINFRA1Job
Write-Host "Complete" -ForegroundColor Green
#endregion

<#
ForEach ($DC in $DCs) {
    Write-Host "Querying $DC" -ForegroundColor Green -BackgroundColor Black
    Get-WinEvent -ComputerName $DC -FilterHashtable @{logname="Security"; StartTime=((Get-Date).AddMinutes(-$Duration)); Id=4740;} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | `
        Where Message -like "*$User*" | `
        Select MachineName, TimeCreated, ID, Message ` |
        Format-Table -AutoSize -Wrap
}
#>