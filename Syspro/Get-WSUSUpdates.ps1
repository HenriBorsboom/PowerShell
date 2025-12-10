Function Update-Host {
    Param ([ValidateSet("Start","Stop")]$Action)

    Switch ($Action) {
        "Start" {
            Write-Host "Getting Updates - " -NoNewline
        }
        "Stop"  {
            Write-Host "Complete" -ForegroundColor Green
        }
    }
}
Function Build-Scripts {
$Approvals = @()
$Approvals += ,("Unapproved")
$Approvals += ,("Declined")
$Approvals += ,("Approved")
$Approvals += ,("AnyExceptDeclined")

$Classifications = @()
$Classifications += ,("All")
$Classifications += ,("Critical")
$Classifications += ,("Security")
$Classifications += ,("WSUS")

$Statuses = @()
$Statuses += ,("Needed")
$Statuses += ,("FailedOrNeeded")
$Statuses += ,("Failed")
$Statuses += ,("InstalledNotApplicable")
$Statuses += ,("NoStatus")
$Statuses += ,("Any")

$Scripts = @()
ForEach ($Approval in $Approvals) {
    ForEach ($Classification in $Classifications) {
        ForEach ($Status in $Statuses) {
            $Scripts += ,('Update-Host -Action Start; $AllUpdates += ,(Get-WsusUpdate -UpdateServer $WSUSServer -Approval ' + $Approval + ' -Classification ' + $Classification + ' -Status ' + $Status + ')')
        }
    }
}

    Return $Scripts
}
$AllUpdates = @()
$WSUSServer = Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530
$Scripts = Build-Scripts
$StartCount = 0
$EndCount   = 0
For ($i = 0; $i -lt $Scripts.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Scripts.Count.ToString() + ' - ') -NoNewline
    $StartCount = $AllUpdates.Count
    Invoke-Expression $Scripts[$i]
    $EndCount = ($AllUpdates - $StartCount)
    Write-Host ("Complete: " + $EndCount.ToString()) -ForegroundColor Green
    $AllUpdates | Out-File ('C:\Temp\Orchestrator\Patches\Patches_' + $i.ToString() + '.txt') -Encoding ascii -Force
}
$AllUpdates | Out-File C:\Temp\Orchestrator\Patches\Patches.txt -Encoding ascii -Force