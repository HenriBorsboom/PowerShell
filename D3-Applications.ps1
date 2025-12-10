# Live
#<#
Param (
    [Parameter(Mandatory=$False, Position=1)]
    [Object[]] $GlobalProcesses, `
    [Parameter(Mandatory=$False, Position=2)]
    [String] $SingleProcess, `
    [Parameter(Mandatory=$False, Position=3)][ValidateSet("Start", "Close")]
    [String] $State, `
    [Parameter(Mandatory=$False, Position=3)][ValidateSet("All", "Failure")]
    [String] $Report)
#>
# Debug
<#
    $GlobalProcesses = $GlobalProcesses
    $Process = $Process
    $State = $State
#>
Function Action-Processes {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [Object[]] $GlobalProcesses, `
        [Parameter(Mandatory=$False, Position=3)][ValidateSet("All", "Failure")]
        [String] $Report)

    If($GlobalProcesses.Count -ne 0) {
        $Processes = $GlobalProcesses
    }
    Else {
        $DefaultProcesses = @(
            "armsvc"
            "atiesrxx"
            "atieclxx"
            "atieclxx"
            "NetFaxServer64"
            "SecUPDUtilSvc"
            "ss_conn_service"
            "vwmpnetwk"
            "SearchIndexer"
            "SearchProtocolHost"
            "EPM2DotNetHandler"
            "NetFaxTray64"
            "EasyPrinterManagerV2"
            "SearchFilterHost"
            "NvBackend")
        $Processes = @()
        ForEach ($Process in $DefaultProcesses) {
            $Object = New-Object -TypeName psobject -Property @{
                Selected = "True"
                ProcessName = $Process
                DisplayName = ""
            }
            $Processes = $Processes + $Object
        }
    }

    $PCount   = $Processes.Count
    $PCounter = 1

    ForEach ($Process in $Processes) {
        Try {
            If ($Process.DisplayName -ne "") { $ProcessName = $Process.DisplayName }
            Else                             { $ProcessName = $Process.ProcessName }
            Write-Color -Text "$PCounter/$PCount", " - Stopping Process - ", $ProcessName, " - " -ForegroundColor Cyan, White, Yellow, White -Nonewline
            Stop-Process -Name $Process.ProcessName -Force -ErrorAction SilentlyContinue -Confirm:$false
            Write-Color -Text "Complete" -ForegroundColor Green
            Switch ($Report) {
                "All"     { }
                "Failure" { Delete-LastLine }
            }
            
        }
        Catch { Write-Color -Text "Failed" -ForegroundColor Green }
        $PCounter ++
    }
}
Function Process-State {
    Param (
        [Parameter(Mandatory=$true, position=1)]
        [String] $Process, `
        [Parameter(Mandatory=$true, position=2)][ValidateSet("Start", "Close")]
        [String] $State)
    
    $StartTime = Get-Date
    $ProcessExist = $True
    
    $Counter = 0
    Switch ($State) {
        "Close" {
            While ( $ProcessExist -eq $True ) {
                Try {
                    Write-Host
                    Delete-LastLine
                    Get-Process -Name $Process -ErrorAction Stop | Out-Null
                    $Duration = Get-TotalTime -StartTime $Counter
                    Write-Color -Text "Closed ", $Process, " - ", $Duration, " - " -ForegroundColor White, Green, White, Cyan, White -Nonewline
                    Sleep 1
                    $Counter ++
                }
                Catch {
                    $Duration = Get-TotalTime -StartTime $StartTime
                    $ProcessExist = $false
                }
            }
        }
        "Start" {
            While ( $ProcessExist -eq $True ) {
                Try {
                    Get-Process -Name $Process -ErrorAction Stop | Out-Null
                    $Duration = Get-TotalTime -StartTime $StartTime
                    $ProcessExist = $false
                }
                Catch {
                    Write-Host
                    Delete-LastLine
                    $Duration = Get-TotalTime -StartTime $Counter
                    Write-Color -Text "Started ", $Process, " - ", $Duration, " - " -ForegroundColor White, Green, White, Cyan, White -Nonewline
                    Sleep 1
                    $Counter++
                }
            }
        }
    }
    Write-Color -Text "Complete" -ForegroundColor Green
}
If ($GlobalProcesses.Count -gt 0) {
    Action-Processes -GlobalProcesses $GlobalProcesses
}
Else {
    Process-State -Process $SingleProcess -State $State
}