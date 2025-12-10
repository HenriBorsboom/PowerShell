Function Start-MultiThreadJob {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $JobName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock)
    $SleepTimer = 1
    $GetChildItemJob = Start-Job -Name $JobName -ArgumentList $ScriptBlock -ScriptBlock {Param($Script); Invoke-Expression $Script} -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Sleep 3
        $SleepTimer ++
    }
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}