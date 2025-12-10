Param (
    [Parameter(Mandatory=$False)]
    [Switch] $StartHome, `
    [Parameter(Mandatory=$False)]
    [Switch] $StartOffice, `
    [Parameter(Mandatory=$False)]
    [Switch] $Stop, `
    [Parameter(Mandatory=$False)]
    [Switch] $Fullstop)

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
    Param (
        [Parameter(Mandatory=$False)]
        [Switch] $Office)
        
    For ($i = 0; $i -lt $Processes.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter ($Processes.Count) -Text "Starting ", $Processes[$i].Name, " " -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        If (($Processes[$i].Arguments) -eq $null) {
            If ($Office -eq $True -and !$ExcludedProcesses.Contains($Processes[$i].Name)) {
                If ((Active-Process -Process $Processes[$i].ProcessName) -eq $False) {
                    Start-Process -FilePath $Processes[$i].Process
                    Start-Wait -Seconds 15 -SpotUpdate
                }
                Else {
                    Write-Color -Text 'Skipped' -ForeGroundColor $MyColors.Warning
                    Continue
                }
            }
        }
        Else {
            If ($Office -eq $True -and !$ExcludedProcesses.Contains($Processes[$i].Name)) {
                If ((Active-Process -Process $Processes[$i].ProcessName) -eq $False) {
                    Start-Process -FilePath  $Processes[$i].Process -ArgumentList $Processes[$i].Arguments
                    Start-Wait -Seconds 15 -SpotUpdate
                }
                Else {
                    Write-Color -Text 'Skipped' -ForeGroundColor $MyColors.Warning
                    Continue
                }
            }
        }
        
    }
}
Function Stop-Working {
    Write-Color -Text 'Terminating ', 'Work Processes' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text
    For ($i = 0; $i -lt $Processes.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter ($Processes.Count) -Text "Starting ", $Processes[$i].Name, " - " -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        Try {
            $TerminateProcess = Get-Process $Processes[$i].ProcessName -ErrorAction Stop
            Write-Color -Text "Terminating ", $Processes[$i].ProcessName -ForegroundColor $MyColors.Text, $MyColors.Value
            Stop-Process $TerminateProcess -ErrorAction Stop
        }
        Catch {
            Write-Color -Text "Failed to find process" -ForegroundColor $MyColors.Error
        }
    }
}
Function Full-Stop {
    Write-Color -Text 'Terminating ', 'All non-default', ' Processes - ' -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        $CurrentProcesses = Get-Process
        Write-Color -Text $CurrentProcesses.Count, ' Found' -ForegroundColor $MyColors.Value, $MyColors.Text
    For ($i = 0; $i -lt $CurrentProcesses.Count; $i ++) {
        Try {
            If (!($DefaultProcesses.Contains($CurrentProcesses[$i].Name))) { 
                Write-Color -IndexCounter $i -TotalCounter ($CurrentProcesses.Count) -Text "Terminating ", $CurrentProcesses[$i].Name, " - " -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
                Stop-Process $CurrentProcesses[$i] -ErrorAction Stop 
                Write-Color -Complete
            }
        }
        Catch {
            Write-Color -Text 'Failed' -ForegroundColor $MyColors.Error
        }
    }
    Read-Host
}

#region Processes
#region My Processes
$Processes = @()
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 0; 
	Name        = 'Outlook'; 
	ProcessName = 'Outlook'; 
	Process     = 'C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE'
	Arguments   = $null }) # Outlook
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 1 ; 
	Name        = 'Opera'       ; 
	ProcessName = 'Opera'          ; 
	Process     = 'C:\Program Files\Opera\launcher.exe'
	Arguments   = $null })
<#
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 2 ; 
	Name        = 'Chrome'      ; 
	ProcessName = 'Chrome'         ; 
	Process     = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
	Arguments   = $null })
#> # Opera
<#
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 3 ; 
	Name        = 'OneNote'     ; 
	ProcessName = 'OneNote'        ; 
	Process     = 'C:\Program Files\Microsoft Office\root\Office16\ONENOTE.EXE'
	Arguments   = $null })
#> # OneNote
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 4 ; 
	Name        = 'RT Checks'   ; 
	ProcessName = 'RT Checks (x64)'; 
	Process     = 'C:\Users\henri.borsboom\Documents\Scripts\Auto-It Scripts\EOH\RT Checks (x64).Exe'
	Arguments   = $null }) # RT Checks
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 5 ; 
	Name        = 'Lync'        ; 
	ProcessName = 'Lync'           ; 
	Process     = 'C:\Program Files\Microsoft Office\root\Office16\lync.exe'
	Arguments   = $null }) # Lync
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 6 ; 
	Name        = 'Telepo'      ; 
	ProcessName = 'SoftPhone'      ; 
	Process     = 'C:\Program Files (x86)\Mitel\Telepo\SoftPhone.exe'
	Arguments   = $null }) # Telepo
$Processes += ,(New-Object -TypeName PSObject -Property @{
	Priority    = 7 ; 
	Name        = 'PulseSecure' ; 
	ProcessName = 'Pulse'          ; 
	Process     = 'C:\Program Files (x86)\Common Files\Pulse Secure\JamUI\Pulse.exe'; 
	Arguments   = [String[]] '-show'}) # Pulse Secure
#endregion
#region Office Exclusions
$ExcludedProcesses = @()
$ExcludedProcesses += ,("Telepo")
$ExcludedProcesses += ,("PulseSecure")
#endregion
#region Default Processes
$DefaultProcesses = @()
$DefaultProcesses += ,("armsvc")
$DefaultProcesses += ,("audiodg")
$DefaultProcesses += ,("conhost")
$DefaultProcesses += ,("csrss")
$DefaultProcesses += ,("ctfmon")
$DefaultProcesses += ,("CxMonSvc")
$DefaultProcesses += ,("CxUtilSvc")
$DefaultProcesses += ,("dptf_helper")
$DefaultProcesses += ,("dwm")
$DefaultProcesses += ,("esif_uf")
$DefaultProcesses += ,("EvtEng")
$DefaultProcesses += ,("explorer")
$DefaultProcesses += ,("Flow")
$DefaultProcesses += ,("fontdrvhost")
$DefaultProcesses += ,("fpCSEvtSvc")
$DefaultProcesses += ,("GoogleCrashHandler")
$DefaultProcesses += ,("GoogleCrashHandler64")
$DefaultProcesses += ,("Greenshot")
$DefaultProcesses += ,("hpMAMSrv")
$DefaultProcesses += ,("IAStorDataMgrSvc")
$DefaultProcesses += ,("IAStorIcon")
$DefaultProcesses += ,("ibtsiva")
$DefaultProcesses += ,("Idle")
$DefaultProcesses += ,("igfxCUIService")
$DefaultProcesses += ,("igfxEM")
$DefaultProcesses += ,("IntelCpHDCPSvc")
$DefaultProcesses += ,("IntelCpHeciSvc")
$DefaultProcesses += ,("jhi_service")
$DefaultProcesses += ,("LMS")
$DefaultProcesses += ,("lsass")
$DefaultProcesses += ,("Memory Compression")
$DefaultProcesses += ,("MicTray64")
$DefaultProcesses += ,("MsMpEng")
$DefaultProcesses += ,("MyAgentProcess")
$DefaultProcesses += ,("MyAgentService")
$DefaultProcesses += ,("MyCommunicationService")
$DefaultProcesses += ,("ngvpnmgr")
$DefaultProcesses += ,("NisSrv")
$DefaultProcesses += ,("NvBackend")
$DefaultProcesses += ,("NVDisplay.Container")
$DefaultProcesses += ,("OfficeHubTaskHost")
$DefaultProcesses += ,("OneDriveStandaloneUpdater")
$DefaultProcesses += ,("PresentationFontCache")
$DefaultProcesses += ,("PulseSecureService")
$DefaultProcesses += ,("Registry")
$DefaultProcesses += ,("RegSrvc")
$DefaultProcesses += ,("RuntimeBroker")
$DefaultProcesses += ,("SearchIndexer")
$DefaultProcesses += ,("SearchUI")
$DefaultProcesses += ,("SecurityHealthService")
$DefaultProcesses += ,("services")
$DefaultProcesses += ,("SettingSyncHost")
$DefaultProcesses += ,("SgrmBroker")
$DefaultProcesses += ,("ShellExperienceHost")
$DefaultProcesses += ,("sihost")
$DefaultProcesses += ,("SkypeHost")
$DefaultProcesses += ,("SmartAudio3")
$DefaultProcesses += ,("smartscreen")
$DefaultProcesses += ,("smss")
$DefaultProcesses += ,("spoolsv")
$DefaultProcesses += ,("svchost")
$DefaultProcesses += ,("SynTPEnh")
$DefaultProcesses += ,("SynTPEnhService")
$DefaultProcesses += ,("SynTPHelper")
$DefaultProcesses += ,("System")
$DefaultProcesses += ,("taskhostw")
$DefaultProcesses += ,("TiWorker")
$DefaultProcesses += ,("TrustedInstaller")
$DefaultProcesses += ,("unsecapp")
$DefaultProcesses += ,("valWBFPolicyService")
$DefaultProcesses += ,("Video.UI")
$DefaultProcesses += ,("vmware-usbarbitrator64")
$DefaultProcesses += ,("wininit")
$DefaultProcesses += ,("winlogon")
$DefaultProcesses += ,("wlanext")
$DefaultProcesses += ,("WmiPrvSE")
$DefaultProcesses += ,("WUDFHost")
$DefaultProcesses += ,("ZeroConfigService")
$DefaultProcesses += ,("powershell")
$DefaultProcesses += ,("powershell_ise")
#endregion
#endregion
$MyColors = @{}
$MyColors.Add("Text",    ([ConsoleColor]::White))
$MyColors.Add("Value",   ([ConsoleColor]::Cyan))
$MyColors.Add("Warning", ([ConsoleColor]::Yellow))
$MyColors.Add("Error",   ([ConsoleColor]::Red))

Switch ($StartHome)   { $True { Start-Working         } }
Switch ($StartOffice) { $True { Start-Working -Office } }
Switch ($Stop)        { $True { Stop-Working          } }
Switch ($Fullstop)    { $True { Full-Stop             } }