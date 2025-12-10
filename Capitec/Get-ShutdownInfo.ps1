Param (
    [Parameter(Mandatory=$False, Position=1)]
    [String] $ComputerName, `
    [Parameter(Mandatory=$False, Position=2)]
    [Switch] $Unexpected, `
    [Parameter(Mandatory=$False, Position=3)]
    [Switch] $Requested
)
Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function Get-UnexpectedShutdowns {
    # Query Unexpected Shutdown
    Write-Color -Text "=================================== ", "Unexpected Shutdowns", " ===================================" -ForegroundColor DarkCyan, Yellow, DarkCyan
    "=================================== Unexpected Shutdowns ===================================" | Out-file $OutputFile -Encoding ascii -Append
        $WMIQuery = "SELECT TimeGenerated from Win32_NTLogEvent WHERE Logfile = 'System' And (EventCode=6008)"
        If ($ComputerName -eq "") {
            $QueryResults = Get-WMIObject -Query $WMIQuery
        }
        Else {
            $QueryResults = Get-WMIObject -Query $WMIQuery -Computername $ComputerName
        }
        For ($i = 0; $i -lt $QueryResults.Count; $i ++) {
            Write-Color -Text "Unexpected Shutdown on: ", ('{0:dd-MM-yyyy HH:mm:ss}' -f ($QueryResults[$i].ConvertToDateTime($QueryResults[$i].TimeGenerated))), " - Event Code: 6008" -ForegroundColor White, Red, White
            ("Unexpected Shutdown on: " + ('{0:dd-MM-yyyy HH:mm:ss}' -f ($QueryResults[$i].ConvertToDateTime($QueryResults[$i].TimeGenerated)))) | Out-File $OutputFile -Encoding ascii -Append
        }
    "============================================================================================" | Out-File $OutputFile -Encoding ascii -Append
    Write-Color -Text "============================================================================================" -ForegroundColor DarkCyan
}
Function Get-RequestedShutdowns {
    # Query Shutdowns
    Write-Color -Text "==================================== ", "Shutdowns Requests", " ====================================" -ForegroundColor DarkCyan, Yellow, DarkCyan
        "==================================== Shutdowns Requests ====================================" | Out-File $OutputFile -Encoding ascii -Append
        $WMIQuery = "SELECT User,TimeGenerated, Message from Win32_NTLogEvent WHERE Logfile = 'System' And (EventCode=1074)"
        If ($ComputerName -eq "") {
            $QueryResults = Get-WMIObject -Query $WMIQuery
        }
        Else {
            $QueryResults = Get-WMIObject -Query $WMIQuery -Computername $ComputerName
        }
        #ForEach ($ShutdownRequest in $QueryResults) {
        For ($i = 0; $i -lt $QueryResults.Count; $i ++) {
            Write-Color -Text "User: ", $QueryResults[$i].User -ForegroundColor DarkCyan, White
            Write-Color -Text "Time: ", ('{0:dd-MM-yyyy HH:mm:ss}' -f ($QueryResults[$i].ConvertToDateTime($QueryResults[$i].TimeGenerated))), " - Event Code: 1074" -ForegroundColor DarkCyan, White, White
            Write-Color -Text "Message: ", $QueryResults[$i].Message -ForegroundColor DarkCyan, White

            ("User: " + $QueryResults[$i].User) | Out-File $OutputFile -Encoding ascii -Append
            ("Time: " + ('{0:dd-MM-yyyy HH:mm:ss}' -f ($QueryResults[$i].ConvertToDateTime($QueryResults[$i].TimeGenerated)))) | Out-File $OutputFile -Encoding ascii -Append
            ("Message: " + $QueryResults[$i].Message) | Out-File $OutputFile -Encoding ascii -Append
            "" | Out-File $OutputFile -Encoding ascii -Append
        }
        "============================================================================================" | Out-File $OutputFile -Encoding ascii -Append
        Write-Color -Text "============================================================================================" -ForegroundColor DarkCyan
}
Clear-Host
If ($ComputerName -eq "") { $Global:ComputerName = $env:COMPUTERNAME }
$OutputFile = ($env:temp + "\" + $ComputerName.ToUpper() + '_' + ('{0:dd-MM-yyyy}' -f (Get-Date)) + ".txt")
If (Test-Path $OutputFile) { Remove-Item $OutputFile }
Get-UnexpectedShutdowns
Get-RequestedShutdowns
Write-Color -Text "Shutdown Information has been exported to ", $Outputfile -ForegroundColor White, Yellow
notepad $Outputfile