Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { 
                Write-Host ("Text            : " + ($Text -join ","))
                write-Host ("Text Count      : " + $Text.Count.ToString())
                write-Host ("Background Count: " + $Text.Count.ToString())
                write-Host ("Foreground Count: " + $Text.Count.ToString())
                Throw 
                
            }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'Normal') { 
            For ($Index = 0; $Index -lt $Text.Length; $Index ++) { 
                Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine 
            } 
        }
        If ($OperationMode -eq 'Complete') { 
            Write-Host 'Complete' -ForegroundColor Green -NoNewLine 
        }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function Start-Wait {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int16] $Seconds)

    If ($Host.Name -notlike '*ISE*') {
        $CursorLeft = [Console]::CursorLeft
        $CursorTop  = [Console]::CursorTop
    
        $CursorIndex = @('-', '\', '|', '/')
        $CurrentSpot = $null
        For ($SecondCount = 0; $SecondCount -lt $Seconds; $SecondCount ++) {
            For ($MillisecondCount = 0; $MillisecondCount -lt 10; $MillisecondCount ++) {
                If ($CurrentSpot -eq $null)              { $CurrentSpot = 0 }
                If ($CurrentSpot -gt $CursorIndex.Count) { $CurrentSpot = 0 }
                Write-Host $CursorIndex[$CurrentSpot] -NoNewline -ForegroundColor Cyan
                $CurrentSpot ++
                [Console]::SetCursorPosition($CursorLeft, $CursorTop)
                Start-Sleep -Milliseconds 100
            }
        }
        Write-Host "Complete" -ForegroundColor Green
    }
    Else {
        For ($SecondCount = 0; $SecondCount -lt $Seconds; $SecondCount ++) {
            Write-Host "." -NoNewline -ForegroundColor Cyan
            Start-Sleep -Seconds 1
        }
    }
}
Function Active-Process {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Process)

    Try {
        Get-Process $Process -ErrorAction Stop
        Return $True
    }
    Catch {
        Return $False
    }
}
Function Start-Working {
    For ($i = 0; $i -lt $Processes.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter ($Processes.Count) -Text "Starting ", $Processes[$i].ProcessName, " " -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        If ((Active-Process -Process $Processes[$i].ProcessName) -eq $False) {
            Start-Process -FilePath $Processes[$i].Process
            Start-Wait -Seconds $Timeout
        }
        Else {
            Write-Color -Text 'Skipped' -ForeGroundColor $MyColors.Warning
            #Continue
        }
    }
}

#region Processes
[Object[]] $Processes = @()
$Processes += ,(New-Object -TypeName PSObject -Property @{
	ProcessName = 'Outlook'; 
	Process     = 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE'}) # Outlook
$Processes += ,(New-Object -TypeName PSObject -Property @{
	ProcessName = 'Opera'; 
	Process     = 'C:\Users\ct302255\AppData\Local\Programs\Opera\launcher.exe'}) # Opera
$Processes += ,(New-Object -TypeName PSObject -Property @{
	ProcessName = 'Move Mouse'          ; 
	Process     = 'C:\Users\ct302255\Downloads\Move Mouse.exe'}) # Move Mouse
<#
$Processes += ,(New-Object -TypeName PSObject -Property @{
	ProcessName = 'RT Checks (x64)'; 
	Process     = 'C:\Users\henri.borsboom\Documents\Scripts\Auto-It Scripts\EOH\RT Checks (x64).Exe'}) # RT Checks
#> # RT Checks
<#$Processes += ,(New-Object -TypeName PSObject -Property @{
	ProcessName = 'Teams'; 
	Process     = 'C:\Users\henri.borsboom\AppData\Local\Microsoft\Teams\current\Teams.exe'})#> # Teams
#endregion

$MyColors = @{}
$MyColors.Add("Text",    ([ConsoleColor]::White))
$MyColors.Add("Value",   ([ConsoleColor]::Cyan))
$MyColors.Add("Warning", ([ConsoleColor]::Yellow))
$MyColors.Add("Error",   ([ConsoleColor]::Red))

$Timeout = 5

Start-Working