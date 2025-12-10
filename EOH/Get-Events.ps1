Param (
    [Parameter(Mandatory=$False)]
    [Switch] $Full = $False, `
    [Parameter(Mandatory=$False)]
    [Switch] $Notepad = $True)
Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
        [Switch] $Complete, `
           [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
           [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host }
        $ErrorActionPreference = $CurrentActionPreference
    }
}

#Variables
$ErrorActionPreference = 'Stop'
[DateTime] $StartDate = '2019/09/08 00:00' -f '{0:yyyy/MM/dd HH:mm}' # (Get-Date).AddHours(-1)
[DateTime] $EndDate   = '2019/09/08 09:05' -f '{0:yyyy/MM/dd HH:mm}' #  Get-Date


Clear-Host
Write-Host "Getting All System logs with records - " -NoNewline
$ActiveLogs = Get-WinEvent -ListLog * | Where-Object {$_.RecordCount -gt 0}
Write-Host ($ActiveLogs.Count.ToString() + ' logs found') -ForegroundColor Green

$AllEvents = @()
$EventCount = 0
For ($LogI = 0; $LogI -lt $ActiveLogs.Count; $LogI ++) {
    Write-Color -IndexCounter $LogI -TotalCounter $ActiveLogs.Count -Text 'Getting logs from ', $ActiveLogs[$LogI].LogName, ' - ' -ForegroundColor White, Yellow, White -NoNewLine
    #Write-Host ("Getting Logs from " + $ActiveLogs[$LogI].LogName + " - ") -NoNewLine
    If ($Full -eq $False) {
        $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate; Level=2,3} -ErrorAction SilentlyContinue 
     }
    Else {
        $LogEvents = Get-WinEvent -FilterHashTable @{ LogName = $ActiveLogs[$LogI].LogName; StartTime = $StartDate; EndTime = $EndDate} -ErrorAction SilentlyContinue
    }
    Write-Host ($LogEvents.Count.ToString() + ' found') -ForegroundColor Green
    ForEach ($Event in $LogEvents) {
        $AllEvents += ,($Event)
    }
    $EventCount += $LogEvents.Count
    $LogEvents = 0
}
$Outfile = ('C:\Temp\Events_' + '{0:yyyy-MM-dd_HH.mm.ss}' -f (Get-Date) + '.txt')
$AllEvents | Format-List | Out-File $Outfile -Force -Encoding ascii
$AllEvents | Format-List
Write-Host
Write-Host "-----------------------------------------------------------------------" -ForegroundColor Red
Write-Color -Text 'Total events recorded: ', $EventCount.ToString() -ForegroundColor White, Yellow
#Write-Host ("Total events recorded: " + $EventCount.ToString())
$AllEvents | Group-Object -Property LevelDisplayName, LogName -NoElement | Format-Table -AutoSize
Write-Host ("Events saved to: ")
Write-Host ("  " + $OutFile) -ForegroundColor Green
Write-Host "-----------------------------------------------------------------------" -ForegroundColor Red
If ($Notepad) { Notepad $Outfile }
