Param (
    [Parameter(Mandatory=$false, Position=1)]
    [ValidateSet(
            "1", 
            ”launchd3”,
            "relaunchd3",
            "2", 
            "launchptr", 
            "relaunchptr",
            "3", 
            "battle.bet", 
            "4", 
            "stopservices", 
            "5", 
            "stopapplication",
            "6", 
            “recover”,
            "7", 
            "recoverOnly")]
    [String] $Action, `
    [Parameter(Mandatory=$false, Position=1)]
    [Switch] $Transcript)
#region Common Functions
Function Delete-LastLine {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x,$y - 1)
        $String = ""
        For ($i = 0; $i -lt $pswindow.windowsize.Width; $i ++) {
            $String = ($String + " ")
        }
    
        Write-Host $String 
        [Console]::SetCursorPosition($x,$y -1)
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

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
        [Parameter(Mandatory=$true,  Position=1)]
        [Object] $StartTime, `
        [Parameter(Mandatory=$false, Position=2)]
        [DateTime] $EndTime)
        
    Switch ($StartTime.GetType().name) {
        "DateTime" {
            If ( $EndTime -eq $null ) { $EndTime = Get-Date }
            $ReturnVariable = ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Start $StartTime -End $EndTime).TotalSeconds))
        }
        "int32" {
            $ReturnVariable = ("{0:hh\:mm\:ss}" -f [TimeSpan]::FromSeconds((New-TimeSpan -Seconds $StartTime).TotalSeconds))
        }
    }
    Return $ReturnVariable
}
Function Recording {
    Param (
        [Parameter(Mandatory=$True,  Position=1)][ValidateSet("Start", "Stop")]
        [String] $Action)
    $TranscriptFile =("C:\Temp\Transcripts\Transcript_" + "{0:dd}.{0:mm}.{0:yyyy}-{0:hh}.{0:mm}.{0:ss}" -f (Get-Date) + ".txt")
    If ($Host.Name -notlike '*ISE*') {
        Switch ($Action) {
            "Start" {
                Start-Transcript -Path $TranscriptFile -NoClobber
            }
            "Stop" {
                Stop-Transcript
            }
        }
    }
}
#endregion
#region Main Functions
Function Load-Settings {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Processes", "FilePaths", "Services", "FailedServices", "FailedProcesses")]
        [String] $Setting)

    Switch ($Setting) {
        "Processes" {
            $ApplicationsSettingsFile      = 'C:\Temp\BattleNet_Applications.txt'
            If (Test-Path $ApplicationsSettingsFile) {
                $ApplicationsSettings = Import-Csv $ApplicationsSettingsFile -Delimiter ","
                Return $ApplicationsSettings
            }
            Else { Return $False }
        }
        "FailedProcesses" {
            $FailedApplicationsSettingsFile      = 'C:\Temp\BattleNet_FailedApplications.txt'
            If (Test-Path $FailedApplicationsSettingsFile) {
                $FailedApplicationsSettings = Import-Csv $FailedApplicationsSettingsFile -Delimiter ","
                Return $FailedApplicationsSettings
            }
            Else { Return $False }
        }
        "FilePaths" {
            $ApplicationsPathsSettingsFile = 'C:\Temp\BattleNet_ApplicationsPaths.txt'
            If (Test-Path $ApplicationsPathsSettingsFile) {
                $ApplicationsPathsSettings = Import-Csv $ApplicationsPathsSettingsFile -Delimiter ","
                Return $ApplicationsPathsSettings
            }
            Else { Return $False }
        }
        "Services" {
            $ServicesSettingsFile          = 'C:\Temp\BattleNet_Services.txt'
            If (Test-Path $ServicesSettingsFile) {
                $ServicesSettings = Import-Csv $ServicesSettingsFile -Delimiter ","
                Return $ServicesSettings
            }
            Else { Return $False }
        }
        "FailedServices" {
            $FailedServicesSettingsFile          = 'C:\Temp\BattleNet_FailedServices.txt'
            If (Test-Path $FailedServicesSettingsFile) {
                $FailedServicesSettings = Import-Csv $FailedServicesSettingsFile -Delimiter ","
                Return $FailedServicesSettings
            }
            Else { Return $False }
        }
    }
    Return $False
}
Function Start-Diablo {
    Param (
        [Parameter(Mandatory=$False, Position=1, ParameterSetName="Normal")][ValidateSet(“Full”,”PTR”)]
        [String] $Version = "Full")

    Write-Host
	If (Test-Path $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('BattleNetFile'))).FilePath) {
		Start-Process -FilePath $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('BattleNetFile'))).FilePath
	}
	Else { Throw }
    & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Start #Process-State -Process "Battle.net" -State Start
    & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Close #Process-State -Process "Battle.net" -State Close
    Switch ($Version) {
        "Full" { & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Diablo III" -State Start }
        "PTR"  { & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Diablo III64" -State Start }
    }
    Stop-Process  -Name     "Agent"      -Force -Confirm:$false -ErrorAction SilentlyContinue
    & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Agent" -State Start      #Process-State -Process "Agent"      -State Close
    & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Start #Process-State -Process "Diablo III" -State Close
    Switch ($Version) {
        "Full" { & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Diablo III" -State Close }
        "PTR"  { & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Diablo III64" -State Close }
    }
    Relaunch-Detection
}
Function Relaunch-Detection {
    Write-Color -Text "---------------", " Relaunch Menu ", "--------------" -ForegroundColor DarkCyan, Yellow, DarkCyan
    Write-Color -Text "1)", " Launch Diablo 3 Retails" -ForegroundColor Green, White
    Write-Color -Text "2)", " Launch Diablo 3 Public Test Realm" -ForegroundColor Green, White
    Write-Color -Text "3)", " Launch Battle.Net" -ForegroundColor Green, White
    Write-Color -Text "4)", " Launch Reset Services and Shutdown" -ForegroundColor Green, White
    Write-Color -Text "5)", " Launch Main Menu" -ForegroundColor Green, White
    Write-Color -Text "6)", " Launch Shutdown immediately" -ForegroundColor Green, White
    Write-Color -Text "Selection (4): " -ForegroundColor Yellow -NoNewLine
    $MenuAnswer = Read-Host
    Switch ($MenuAnswer) {
        "1" {
            Invoke-Expression 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\Slash\Documents\Scripts\PowerShell\D3.ps1 -Action RelaunchD3'
        }
        "2" {
            Invoke-Expression 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\Slash\Documents\Scripts\PowerShell\D3.ps1 -Action RelaunchDTR'
        }
        "3" {
            Invoke-Expression 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\Slash\Documents\Scripts\PowerShell\D3.ps1 -Action Battle.Net'
        }
        "4" {
            Action-Items -Action Start
            Stop-Computer -Force
        }
        "5" {
            Launch-Menu
        }
        "6" {
            Stop-Computer -Force
        }
        "" {
            Action-Items -Action Start
            Stop-Computer -Force
        }
        Default {
            Relaunch-Detection
        }
    }
}
Function Action-Items {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet(“Start”,”Stop”)]
        [String] $Action, `
        [Parameter(Mandatory=$False, Position=4)][ValidateSet("Details", "Matches", "Mismatches","FailedServices")]
        [String] $Report)

    Switch ($Action) {
        "Start" { 
            If ($Report -eq $null -or $Report -eq "") {
                & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Start
            }
            Else {
                & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Start -Report $Report
            }
        }
        "Stop"  { 
            If ($Report -eq $null -or $Report -eq "") {
                & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop
            }
            Else {
                & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop -Report $Report
            }
            & 'C:\Users\Slash\D3-Applications.ps1' -GlobalProcesses $GlobalProcesses
        }
    }
}
Function Launch-Menu {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $QuickAction)
    
    If ($QuickAction -eq "") { 
        #region Menu Drawing
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "-------------------", " Menu ", "-------------------" -ForegroundColor DarkCyan, Yellow, DarkCyan
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "1) ", " Launch Diablo 3 Retails" -ForegroundColor Green, White
        Write-Color -Text "2) ", " Launch Diablo 3 Public Test Realm" -ForegroundColor Green, White
        Write-Color -Text "3) ", " Launch Battle.Net" -ForegroundColor Green, White
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "4) ", " Stop Services" -ForegroundColor Green, White
        Write-Color -Text "5) ", " Stop Applications" -ForegroundColor Green, White
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "6) ", " Start Services" -ForegroundColor Green, White
        Write-Color -Text "7) ", " Start Services and quit" -ForegroundColor Green, White
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "8) ", " Compare Services Detailed" -ForegroundColor Green, White
        Write-Color -Text "9) ", " Compare Services Matches" -ForegroundColor Green, White
        Write-Color -Text "10)", " Compare Services Mismatches" -ForegroundColor Green, White
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "x)", " Exit" -ForegroundColor Green, White
        Write-Color -Text "--------------------------------------------" -ForegroundColor DarkCyan
        Write-Color -Text "Selection (x): " -ForegroundColor Yellow -NoNewLine
        $MenuAnswer = (Read-Host).ToLower()
        #endregion
    }
    Else {
        $MenuAnswer = $QuickAction
    }
    Switch ($MenuAnswer) {
        "1" {
            Action-Items -Action Stop 
            Start-Diablo -Version Full
        }
        "launchd3" {
            Action-Items -Action Stop
			Start-Diablo -Version Full
        }
        "relaunchd3" {
            Start-Diablo -Version Full
        }
        "2" {
            Action-Items -Action Stop
			Start-Diablo -Version PTR
        }
        "launchptr" {
            Action-Items -Action Stop
			Start-Diablo -Version PTR
        }
        "relaunchptr" {
            Start-Diablo -Version PTR
        }
        "3" {
			Start-Process -FilePath $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('BattleNetFile'))).FilePath
			& 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Start
            & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Close
        }
        "battle.net" {
			Start-Process -FilePath $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('BattleNetFile'))).FilePath
			& 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Start
            & 'C:\Users\Slash\D3-Applications.ps1' -SingleProcess "Battle.net" -State Close
        }
        "4" {
            & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop -Report FailedServices
            Read-Host "Continue"
            Launch-Menu
        }
        "stopservices" {
            & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop -Report FailedServices
            Read-Host "Continue"
            Launch-Menu
        }
        "5" {
            & 'C:\Users\Slash\D3-Applications.ps1' -GlobalProcesses $GlobalProcesses -Report All
            Read-Host "Continue"
            Launch-Menu
        }
        "stopapplication" {
            & 'C:\Users\Slash\D3-Applications.ps1' -GlobalProcesses $GlobalProcesses
            Read-Host "Continue"
            Launch-Menu
        }
        "6" {
            Action-Items -Action Start -Report FailedServices
            Launch-Menu
        }
        "recover" {
            Action-Items -Action Start
            Launch-Menu
        }
        "7" {
            Action-Items -Action Start
        }
        “recovernnly”
         {
            Action-Items -Action Start
        }
        "8" {
            & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Report Details
            #& 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Update
            Read-Host "Continue"
            Launch-Menu
        }
        "9" {
            & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Report Matches
            Read-Host "Continue"
            Launch-Menu
        }
        "10" {
            & 'C:\Users\Slash\D3-Services.ps1' -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Report Mismatches
            Read-Host "Continue"
            Launch-Menu
        }
        "x" { }
        Default { }
    }
}
#endregion
If ($Transcript) { Recording -Action Start }
#region Global Variables
$D3ServicesScript     = 'C:\Users\Slash\Documents\Scripts\PowerShell\D3-Services.ps1' #-FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Start #-Report FailedServices
$D3ApplicationsScript = 'C:\Users\Slash\Documents\Scripts\PowerShell\D3-Applications.ps1' #-GlobalProcesses $GlobalProcesses -SingleProcess $Process -State Close
$D3LauncherScript     = 'C:\Users\Slash\Documents\Scripts\PowerShell\D3-Launcher.ps1'
$PowerShellExe        = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"

$GlobalFilePaths       = Load-Settings -Setting FilePaths
$GlobalServices        = Load-Settings -Setting Services
$GlobalFailedServices  = Load-Settings -Setting FailedServices
$GlobalProcesses       = Load-Settings -Setting Processes
$GlobalFailedProcesses = Load-Settings -Setting FailedProcesses
$ErrorActionPreference = "Stop"
$WarningPreference     = "SilentlyContinue"
#endregion
Launch-Menu -QuickAction $Action

If ($Transcript) { Recording -Action Stop }
