Write-Host "Getting VM Hosts - " -NoNewline
    $VMHosts = Get-SCVMHost -VMMServer $VMMServer 
    $VMHostCounter = 1
    $VMHostCount = $VMHosts.Count
    $VMHosts = $VMHosts | Sort Name
    $VMHosts = $VMHosts.Name
Write-Host "Complete" -ForegroundColor Green -NoNewline; Write-Host " - " -NoNewline ; Write-Host "$VMHostCount Hosts Found" -ForegroundColor Yellow

ForEach ($VMHost in $VMHosts) {
    Write-Host "$VMHostCounter/$VMHostCount" -ForegroundColor Cyan -NoNewline; Write-Host " - Refreshing " -NoNewline; Write-Host $VMHost.ToUpper() -NoNewline -ForegroundColor Yellow; write-host " - " -NoNewline
        If ($VMHost -ne "NRAZUREVMH101") {
        $GetChildItemJob = Start-Job -Name "Folders" -ArgumentList $VMHost -ScriptBlock {Param($VMHost); Get-SCVMHost -ComputerName $VMHost | Read-SCVMHost} -ErrorAction Stop
        $GetChildItemJobState = Get-Job $GetChildItemJob.Id
        If ($GetChildItemJobState.State -ne "Running") { Write-Host "Error" -ForegroundColor Red; Receive-Job -Job $GetChildItemJob; Exit-PSSession 1}
        While ($GetChildItemJobState.State -eq "Running") {
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Sleep 3
            $x ++
        }
        $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Write-Host " - " -NoNewline
    Write-Host "Complete" -ForegroundColor Green
    }
    $VMHostCounter ++
}