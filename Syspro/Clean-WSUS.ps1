Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ServerName = 'SYSJHBSYSCENTRE.sysproza.net', `
    [Parameter(Mandatory=$False, Position=2)]
    [Int] $Port = 8530, `
    [Parameter(Mandatory=$False, Position=3)][ValidateSet('CleanupObsoleteComputers','CleanupObsoleteUpdates', 'CleanupUnneededContentFiles', 'CompressUpdates', 'DeclineExpiredUpdates', 'DeclineSupersededUpdates')]
    [String] $Action)

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1, ParameterSetName="Text")]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2, ParameterSetName="Text")]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3, ParameterSetName="Text")]
        [Switch]           $NoNewLine, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $Complete)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $ForegroundColor.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $ForegroundColor.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $ForegroundColor[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { 
        Write-Host "Text Count:  " $Text.Count
        Write-Host "Color Count: " $ForegroundColor.Count
        Write-Host $_
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function New-WSUSJob {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Script)

    
    $ThisJob = Start-Job -ScriptBlock {Param ($Script); Invoke-Expression $Script} -ArgumentList $Script
    While ($ThisJob.State -eq 'Running') {
        Delete-Spot
        Start-Sleep -Milliseconds 100
    }
    $JobResults = Receive-Job $ThisJob
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
Function Reset-Globals {
    $Global:CurrentSpot   = 0
    $Global:MilliCounter  = 0 
    $Global:SecondCounter = 0
}
Function Update-Host {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Script)
    Reset-Globals
    $StartTime  = Get-Date
    $JobResults = New-WSUSJob -Script $Script
    $EndTime    = Get-Date
    $Duration   = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
    Write-Color -Text $JobResults, ' - ', $Duration -ForegroundColor Yellow, White, DarkCyan
}
Function Process-WSUS {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $ServerName, `
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $Port, `
        [Parameter(Mandatory=$False, Position=3)][ValidateSet('CleanupObsoleteComputers','CleanupObsoleteUpdates', 'CleanupUnneededContentFiles', 'CompressUpdates', 'DeclineExpiredUpdates', 'DeclineSupersededUpdates')]
        [String] $Action)

    Import-Module UpdateServices

    Write-Color -Text 'Connecting to ', $ServerName, ':', $Port, ' - ' -ForegroundColor White, DarkCyan, White, DarkCyan, White -NoNewLine
        $Global:WSUSServer = Get-WsusServer -Name $ServerName -PortNumber $Port
    Write-Color -Text 'Complete' -ForegroundColor Green

    Switch ($Action) {
        'CleanupObsoleteComputers' {
            Write-Color -Text 'Cleaning up of Obsolete Computers', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteComputers')
                Update-Host -Script $ThisScript
        }
        'CleanupObsoleteUpdates' {
            Write-Color -Text 'Cleaning up of Obsolete Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteUpdates')
                Update-Host -Script $ThisScript
        }
        'CleanupUnneededContentFiles' {
            Write-Color -Text 'Cleaning up of Unneeded Content Files', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupUnneededContentFiles')
                Update-Host -Script $ThisScript
        }
        'CompressUpdates' {
            Write-Color -Text 'Compressing Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CompressUpdates ')
                Update-Host -Script $ThisScript
        }
        'DeclineExpiredUpdates' {
            Write-Color -Text 'Declining Expired Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineExpiredUpdates')
                Update-Host -Script $ThisScript
        }
        'DeclineSupersededUpdates' {
            Write-Color -Text 'Declining Superseded Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineSupersededUpdates')
                Update-Host -Script $ThisScript
        }
        Default {
            Write-Color -Text 'Cleaning up of Obsolete Computers', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteComputers')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Cleaning up of Obsolete Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupObsoleteUpdates')
                Update-Host -Script $ThisScript
    
            Write-Color -Text 'Cleaning up of Unneeded Content Files', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CleanupUnneededContentFiles')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Compressing Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -CompressUpdates ')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Declining Expired Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineExpiredUpdates')
                Update-Host -Script $ThisScript

            Write-Color -Text 'Declining Superseded Updates', ' - ' -ForegroundColor Cyan, White -NoNewLine
                $ThisScript = @('Invoke-WsusServerCleanup -UpdateServer (Get-WsusServer -Name ' + $ServerName + ' -PortNumber ' + $Port + ') -DeclineSupersededUpdates')
                Update-Host -Script $ThisScript
        }
    }
}
Function Delete-Spot {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        If ($Global:MilliCounter -eq $null)                  { $Global:MilliCounter = 0; $Global:SecondCounter = 0 }
        If ($Global:MilliCounter -gt 10)                     { $Global:MilliCounter = 0; $Global:SecondCounter ++ }
        Write-Host ("[" + ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Seconds $SecondCounter).TotalSeconds)) + "] " + $CursorIndex[$Global:CurrentSpot]) -ForegroundColor DarkGreen -NoNewline
        $Global:CurrentSpot ++
        $Global:MilliCounter ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
}


$ServerName = 'SYSCTSTORE.sysproza.net'
$Port       = '8530'
$Action     = 'CompressUpdates'
Switch ($Action) {
    'CleanupObsoleteComputers' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action CleanupObsoleteComputers
    }
    'CleanupObsoleteUpdates' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action CleanupObsoleteUpdates
    }
    'CleanupUnneededContentFiles' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action CleanupUnneededContentFiles
    }
    'CompressUpdates' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action CompressUpdates
    }
    'DeclineExpiredUpdates' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action DeclineExpiredUpdates
    }
    'DeclineSupersededUpdates' {
        Process-WSUS -ServerName $ServerName -Port $Port -Action DeclineSupersededUpdates
    }
    Default {
        Process-WSUS -ServerName $ServerName -Port $Port 
    }
}
