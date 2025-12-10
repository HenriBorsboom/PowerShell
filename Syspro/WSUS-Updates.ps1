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
Function Update-Host {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String[]] $Script)
    Reset-Globals
    $StartTime  = Get-Date
    $JobResults = New-WSUSJob -Script $Script
    $EndTime    = Get-Date
    $Duration   = Get-TotalTime -StartTime $StartTime -EndTime $EndTime
    Write-Color -Text $Duration -ForegroundColor DarkCyan
}
Function Reset-Globals {
    $Global:CurrentSpot   = 0
    $Global:MilliCounter  = 0 
    $Global:SecondCounter = 0
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
Clear-Host

$Scripts = @()
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved'), 'Approval Unapproved')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Unapproved'), 'Approval Unapproved')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Declined'), 'Approval Declined')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval Approved'), 'Approval Approved')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Approval AnyExceptDeclined'), 'Approval AnyExceptDeclined')

$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Classification All'), 'Classification All')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Classification Critical'), 'Classification Critical')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Classification Security'), 'Classification Security')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Classification WSUS'), 'Classification WSUS')
		 
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status Needed'), 'Status Needed')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status FailedOrNeeded'), 'Status FailedOrNeeded')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status InstalledNotApplicableOrNoStatus'), 'Status InstalledNotApplicableOrNoStatus')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status Failed'), 'Status Failed')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status InstalledNotApplicable'), 'Status InstalledNotApplicable')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status NoStatus'), 'Status NoStatus')
$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530) -Status Any'), 'Status Any')

$Scripts += ,(@('Get-WsusUpdate -UpdateServer (Get-WsusServer -Name SYSJHBSYSCENTRE -PortNumber 8530)'), 'Any Any')
$FullResults = @()
ForEach ($Script in $Scripts) {
Write-Color -Text 'Getting ', $Script[1], ' - ', $Script[0], ' - ' -ForegroundColor White, Yellow, White, DarkCyan, White -NoNewLine
    $Updates = Update-Host -Script $Script[0]
    If ($Updates.Count -gt 0) {
        $ThisResult = New-Object -TypeName PSObject -Property @{
            Setting = $Script[1]
            Script  = $Script[0]
            Updates = $Updates
        }
        $ThisResult | Select Setting, Script, Updates | Format-Table -AutoSize
        $FullResults += ,($ThisResult)
    }
    Else {
        Write-Host "No updates found" -ForegroundColor Yellow
    }
}
$FullResults | Out-File C:\temp\Updates.txt -Encoding ascii -Force
$FullResults