Function Job-Reference {
    Write-Host "Starting Job - " -NoNewline
    $TestJob = Start-Job -ScriptBlock { sleep 5 }
    $StartTime = Get-Date
    While ($TestJob.State -eq "Running") {
        Delete-Spot
        Start-Sleep -Milliseconds 100
    }
    $EndTime = Get-Date
    $Duration = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
    Write-Host "$Duration - Complete"
}