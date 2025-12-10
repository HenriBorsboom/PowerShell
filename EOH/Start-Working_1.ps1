Function Set-SpotProgress {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        Write-Host $CursorIndex[$Global:CurrentSpot] -NoNewline -ForegroundColor Cyan
        $Global:CurrentSpot ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
}
Function Start-Wait {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int64] $Seconds, `
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $SpotUpdate)

    For ($i = 0; $i -lt $Seconds; $i ++) { 
        If ($SpotUpdate -eq $True) {
            For ($x = 0; $x -lt 10; $x ++) {
                Set-SpotProgress
                Start-Sleep -Milliseconds 100
            }
        }
        Else {
            Write-Host "." -ForegroundColor Cyan -NoNewline; 
            Start-Sleep -Seconds 1
        }
    }
    Write-Color -Complete
}
Clear-Host
$Processes = @()
# $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 0; Name = ''; Process=''})
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 0; 
    Name        = 'Outlook'; 
    ProcessName = 'Outlook'; 
    Process     ='C:\Program Files\Microsoft Office\Office16\OUTLOOK.EXE'
    Arguments   = $null })
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 1 ; 
    Name        = 'Opera'       ; 
    ProcessName = 'Opera'          ; 
    Process     ='C:\Program Files\Opera\launcher.exe'
    Arguments   = $null })
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 2 ; 
    Name        = 'Chrome'      ; 
    ProcessName = 'Chrome'         ; 
    Process     ='C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
    Arguments   = $null })
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 3 ; 
    Name        = 'OneNote'     ; 
    ProcessName = 'OneNote'        ; 
    Process     ='C:\Program Files\Microsoft Office\Office16\ONENOTE.EXE'
    Arguments   = $null })
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 4 ; 
    Name        = 'RT Checks'   ; 
    ProcessName = 'RT Checks (x64)'; 
    Process     ='C:\Users\henri.borsboom\Documents\Scripts\Auto-It Scripts\EOH\RT Checks (x64).Exe'
    Arguments   = $null })
<#$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 5 ; 
    Name        = 'Lync'        ; 
    ProcessName = 'Lync'           ; 
    Process     ='C:\Program Files\Microsoft Office\Office16\lync.exe'
    Arguments   = $null })#>
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 6 ; 
    Name        = 'Telepo'      ; 
    ProcessName = 'SoftPhone'      ; 
    Process     ='C:\Program Files (x86)\Mitel\Telepo\SoftPhone.exe'
    Arguments   = $null })
$Processes += ,(New-Object -TypeName PSObject -Property @{
    Priority    = 7 ; 
    Name        = 'PulseSecure' ; 
    ProcessName = 'Pulse'          ; 
    Process     ='C:\Program Files (x86)\Common Files\Pulse Secure\JamUI\Pulse.exe'; 
    Arguments   = [String[]] '-show'})

For ($i = 0; $i -lt $Processes.Count; $i ++) {
    Write-Color -IndexCounter $i -TotalCounter ($Processes.Count) -Text "Starting ", $Processes[$i].Name, " " -ForegroundColor White, Yellow, White -NoNewLine
    If (($Processes[$i].Arguments) -eq $null) {
        Start-Process -FilePath $Processes[$i].Process
    }
    Else {
        Start-Process -FilePath $Processes[$i].Process -ArgumentList $Processes[$i].Arguments
    }
    Start-Wait -Seconds 15 -SpotUpdate
}