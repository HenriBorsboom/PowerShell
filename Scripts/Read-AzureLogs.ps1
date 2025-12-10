Param (
        [Parameter(Mandatory=$true,Position=1)]
        [Bool] $Continues, `
        [Parameter(Mandatory=$true,Position=2)]
        [Int64] $PauseDuration, `
        [Parameter(Mandatory=$false,Position=2)]
        [Int64] $LoopCount)

Function Delete-LastLine {
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    [Console]::SetCursorPosition($x,$y - 1)
    Write-Host "                                                                                                                                            "
    [Console]::SetCursorPosition($x,$y - 1)
}

Function Read-AzureLogs {
    #region Definitions and Variables
    Clear-Host
    $Servers = @(
        "NRAZUREAPP105", `
        "NRAZUREAPP106", `
        "NRAZUREAPP107", `
        "NRAZUREAPP108", `
        "NRAZUREAPP109", `
        "NRAZUREAPP110", `
        "NRAZUREAPP111")
    #endregion

    #region Obtain WAP Logs on servers
    Write-Host "Obtaining WAP Logs - "-ForegroundColor Cyan -NoNewline
        $WAPLogsJobs = Invoke-Command -ComputerName $Servers -ScriptBlock {Get-WinEvent -ListLog *  -Force -ErrorAction SilentlyContinue | where LogName -like 'Microsoft-WindowsAzurePack-*'} -AsJob | Wait-Job
    Write-Host "Complete" -ForegroundColor Green
    #$WAPLogsJobs.ChildJobs
    #endregion

    #region Obtain WAP Events on Servers
    $LogEventJobs = @()
    ForEach ($WAPLogsJob in $WAPLogsJobs.ChildJobs) {
        $ServerWAPLogsJob = Receive-Job -Job $WAPLogsJob
        Write-Host "Reading Logs on " -NoNewline
        Write-Host $ServerWAPLogsJob[0].PSComputerName "- "-ForegroundColor Cyan -NoNewline
            $ServerLogsJobs = Invoke-Command -ComputerName $ServerWAPLogsJob[0].PSComputerName -ArgumentList (,$ServerWAPLogsJob.LogName) -ScriptBlock {Param([String[]]$LogNames); Get-WinEvent -FilterHashtable @{logname=$LogNames; StartTime=((Get-Date).AddMinutes(-10))} -MaxEvents 10 -Oldest -Force -ErrorAction SilentlyContinue | Format-Table -AutoSize -Wrap} -AsJob | Wait-Job
        Write-Host "Complete" -ForegroundColor Green
        $LogEventJobs = $LogEventJobs + $ServerLogsJobs.ChildJobs
    }
    #endregion

    #region Collect All Events
    $AllEvents = @()
    Write-Host "Joining Log information - " -ForegroundColor Cyan -NoNewline
    ForEach($LogEventJob in $LogEventJobs) {
        $Events = Receive-Job -Job $LogEventJob
        $AllEvents = $AllEvents + $Events
    }
    Write-Host "Complete" -ForegroundColor Green
    #endregion

    #region Display and export
    $FileDate = Get-Date -UFormat "%Y-%m-%d"
    $FileName = "$env:userprofile\Desktop\WAPLogs-$FileDate.txt"

    Write-Host "Exporting to file " -NoNewline
    Write-Host $FileName "- " -ForegroundColor Cyan -NoNewline
    Remove-Item "$env:userprofile\Desktop\WAPLogs-$FileDate.txt" -Force -ErrorAction SilentlyContinue
    $AllEvents
    #$AllEvents | Out-File -FilePath "$env:userprofile\Desktop\WAPLogs-$FileDate.txt" -Encoding ascii -Append -Width 4096
    Write-Host "Complete" -ForegroundColor Green

    #endregion



    #Notepad $FileName
}
Function Loop {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [Bool] $Continues, `
        [Parameter(Mandatory=$true,Position=2)]
        [Int64] $PauseDuration, `
        [Parameter(Mandatory=$false,Position=2)]
        [Int64] $LoopCount)

    Switch ($Continues) {
        $true {
            For ($x = 1; $x -lt 1000000; $x ++) {
                Read-AzureLogs
                Write-Host "------------- Pause -------------" -ForegroundColor Yellow
                Write-Host "-------------- $PauseDuration ---------------" -ForegroundColor Yellow
                Write-Host "--------------- $x ---------------" -ForegroundColor Yellow

                Pause-Duration $PauseDuration
            }
        }
        $false {
            For ($x = 1; $x -lt ($LoopCount +1); $x ++) {
               .\Read-AzureLogs
                Write-Host "------------- Pause -------------" -ForegroundColor Yellow
                Pause-Duration $PauseDuration
            }
        }
    }
}

Function Pause-Duration {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [Int64] $Duration)

    For ($Delay = 1; $Delay -lt $Duration; $Delay ++) {
        Write-Host "|-- Waiting " -NoNewLine
        Write-Host $Delay -ForegroundColor Red -NoNewline
        Write-Host "/$Duration Seconds -- "
        Sleep 1
        Delete-LastLine
    }
}

Loop -Continues $Continues -PauseDuration $PauseDuration -LoopCount $LoopCount