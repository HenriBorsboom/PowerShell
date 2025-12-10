Param (
    [Parameter(Mandatory=$False, Position=0)][ValidateSet("Get-ServiceInfo","Set-DefaultD3Services","Process-Services","Compare-Services","Reset-ServiceRemotely")]
    [String] $Function, `
    [Parameter(Mandatory=$False, Position=1)][ValidateSet("Start","Stop","AdminStart","AdminStop")]
    [String] $Action, `
    [Parameter(Mandatory=$False, Position=2)]
    [Object[]] $Services, `
    [Parameter(Mandatory=$False, Position=3)][ValidateSet("Details", "Matches", "Mismatches")]
    [String] $Report, `
    [Parameter(Mandatory=$False, Position=4)]
    [String] $FilePath)

Function Get-ServiceInfo {
    $AllServices     = Get-WmiObject -Class Win32_Service 
    $TotalCount      = $AllServices.Count
    $AutoCount       = ($AllServices | Where-Object { $_.StartMode -eq 'Auto' }).Count
    $ManualCount     = ($AllServices | Where-Object { $_.StartMode -eq 'Manual' }).Count
    $DisabledCount   = ($AllServices | Where-Object { $_.StartMode -eq 'Disabled' }).Count

    $AutoService     = ($AllServices | Where-Object { $_.StartMode -eq 'Auto' }     | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $ManualService   = ($AllServices | Where-Object { $_.StartMode -eq 'Manual' }   | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $DisabledService = ($AllServices | Where-Object { $_.StartMode -eq 'Disabled' } | Sort DisplayName | Select DisplayName, Name, StartMode, State)
    $ReturnServiceInfo = New-Object -TypeName PSObject -Property @{
        Services        = $AllServices
        TotalCount      = $TotalCount
        AutoCount       = $AutoCount
        ManualCount     = $ManualCount
        DisabledCount   = $DisabledCount
        AutoService     = $AutoService
        ManualService   = $ManualService
        DisabledService = $DisabledService
    }
    Return $ReturnServiceInfo
}
Function Process-Error {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $CaughtError)

    $ErrorMessages = (($CaughtError.Exception.GetBaseException()).ToString() -split ": ")
    Write-Color -Text $ErrorMessages[1] -ForegroundColor Red
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
Function Set-DefaultD3Services {
    $Services = @(
        "Application Experience"
        "Base Filtering Engine"
        "Cryptographic Services"
        "Desktop Window Manager Session Manager"
        "Diagnostic Policy Service"
        "Distributed Link Tracking Client"
        "Extensible Authentication Protocol"
        "Function Discovery Provider Host"
        "Function Discovery Resource Publication"
        "HomeGroup Listener"
        "HomeGroup Provider"
        "Human Interface Device Access"
        "IKE and AuthIP IPsec Keying Modules"
        "IP Helper"
        "IPsec Policy Agent"
        "Offline Files"
        "Peer Name Resolution Protocol"
        "Peer Networking Grouping"
        "Peer Networking Identity Manager"
        "Portable Device Enumerator Service"
        "Print Spooler"
        "Program Compatibility Assistant Service"
        "SAMSUNG Mobile Connectivity Service"
        "Samsung Network Fax Server"
        "Samsung Printer Dianostics Service"
        "Samsung UPD Utility Service"
        "Security Center"
        "Shell Hardware Detection"
        "Software Protection"
        "SPP Notification Service"
        "Themes"
        "UPnP Device Host"
        "VNC Server"
        "Windows Connect Now - Config Registrar"
        "Windows Firewall"
        "Windows Image Acquisition (WIA)"
        "Windows Media Player Network Sharing Service"
        "Windows Search"
        "Windows Update"
        "WLAN AutoConfig")
    $ServiceDetails = @()
    $ServiceDetailsProperties = @(
        "Selected"
        "DisplayName"
        "ServiceState"
        "StartMode"
        "ServiceName")

    ForEach ($Service in $Services) {
        Try {
            Write-Color -Text "Getting config of ", $Service, " - " -ForegroundColor White, Yellow, White -Nonewline
            $ServiceObject = (Get-Service -DisplayName $Service -ErrorAction Stop)
            $ServiceName = $ServiceObject.Name
            $Result = (Get-WmiObject -Query "Select StartMode From Win32_Service Where Name='$ServiceName'").StartMode
            
            $ServiceObject = New-Object PSObject -Property @{
                Selected     = "True"
                DisplayName  = $ServiceObject.DisplayName
                ServiceState = $ServiceObject.Status
                StartMode    = $Result
                ServiceName  = $ServiceName
            }
            Write-Color -Text "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Color "Failed" -ForegroundColor Red, White, Yellow
        }
        Finally {
            $ServiceDetails = $ServiceDetails + ($ServiceObject | Select $ServiceDetailsProperties)
        }
    }
    If (Test-Path $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('ServicesSettingsFile'))).FilePath) {
        $ServicesSettingsFile = $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('ServicesSettingsFile'))).FilePath
        $ServiceDetails | Export-Csv -Path $ServicesSettingsFile -Force -NoClobber -NoTypeInformation -Encoding ASCII -Delimiter "," 
    }
    Else { 
        $ServicesSettingsFile = 'C:\Temp\BattleNet_Services.txt'
        $ServiceDetails | Export-Csv -Path $ServicesSettingsFile -Force -NoClobber -NoTypeInformation -Encoding ASCII -Delimiter ","        
    }
    Return $ServiceDetails
}
Function Process-Services {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("Start","Stop","AdminStart","AdminStop")]
        [String] $Action)

    If ($GlobalServices.Count -gt 0) {
        $Services = $GlobalServices
    }
    Else {
        $Services = Set-DefaultD3Services
    }
    $SCount   = $Services.Count
    $SCounter = 1

    $FailedServices = @()
    $FailedServicesProperties = @(
        "Action", 
        "Selected", 
        "Error", 
        "ServiceName", 
        "DisplayName", 
        "ServiceState", 
        "StartMode")

    ForEach ($Service in $Services) {
        #If ($RetryFailedServices -eq $false) {
        $SkipAction = $False
        If ($GlobalFailedServices.ServiceName.Contains($Service.ServiceName)) {
            $SkipAction = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Action
            $FailedService = New-Object -TypeName PSObject -Property @{
                Action       = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Action
                Selected     = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Selected
                Error        = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Error
                ServiceName  = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).ServiceName
                DisplayName  = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).DisplayName
                ServiceState = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).ServiceState
                StartMode    = $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).StartMode
            }
            $FailedServices = $FailedServices + $FailedService
        }
        #}
        Try {
            Switch ($Action) {
                "Start" {
                    Write-Color -Text "$SCounter/$SCount", " - Starting Service - ", $Service.DisplayName, " - " -ForegroundColor Cyan, White, Yellow, White -Nonewline
                    If ($SkipAction -eq $False -or $Action -eq "AdminStart") { 
                        If ((Reset-ServiceConfig -ConfigService $Service) -eq $False) { Throw }
                        Write-Host "Complete" -ForegroundColor Green 
                        Delete-LastLine
                    }
                    Else {
                        Write-Color -Text "Skipping", " - ", $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Error -ForegroundColor Magenta, White, Red
                    }
                    
                }
                "AdminStart" {
                    Write-Color -Text "$SCounter/$SCount", " - Starting Service - ", $Service.DisplayName, " - " -ForegroundColor Cyan, White, Yellow, White -Nonewline
                    If ($SkipAction -eq $False -or $Action -eq "AdminStart") { 
                        If ((Reset-ServiceConfig -ConfigService $Service) -eq $False) { Throw }
                        Write-Host "Complete" -ForegroundColor Green 
                        Delete-LastLine
                    }
                    Else {
                        Write-Color -Text "Skipping", " - ", $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Error -ForegroundColor Magenta, White, Red
                    }
                }
                "Stop" {
                    Write-Color -Text "$SCounter/$SCount", " - Stopping Service - ", $Service.DisplayName, " - " -ForegroundColor Cyan, White, Yellow, White -Nonewline
                    If ($SkipAction -eq $False -or $Action -eq "AdminStop") { 
                        Stop-Service -Name $Service.ServiceName -Force -ErrorAction Stop -Confirm:$false -WarningAction SilentlyContinue | Out-Null
                        Set-Service -Name $Service.ServiceName -StartupType Disabled -ErrorAction Stop | Out-Null
                        Write-Color -Text "Complete" -ForegroundColor Green
                        Delete-LastLine
                    }
                    Else {
                        Write-Color -Text "Skipping", " - ", $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Error -ForegroundColor Magenta, White, Red
                    }
                }
                "AdminStop" {
                    Write-Color -Text "$SCounter/$SCount", " - Stopping Service - ", $Service.DisplayName, " - " -ForegroundColor Cyan, White, Yellow, White -Nonewline
                    If ($SkipAction -eq $False -or $Action -eq "AdminStop") { 
                        Stop-Service -Name $Service.ServiceName -Force -ErrorAction Stop -Confirm:$false -WarningAction SilentlyContinue | Out-Null
                        Set-Service -Name $Service.ServiceName -StartupType Disabled -ErrorAction Stop | Out-Null
                        Write-Color -Text "Complete" -ForegroundColor Green
                        Delete-LastLine
                    }
                    Else {
                        Write-Color -Text "Skipping", " - ", $GlobalFailedServices.Item(($GlobalFailedServices.ServiceName.IndexOf($Service.ServiceName))).Error -ForegroundColor Magenta, White, Red
                    }
                }
            }
        }
        Catch {
            $ErrorMessages = (($_.Exception.GetBaseException()).ToString() -split ": "); 
            $FailedService = New-Object -TypeName PSObject -Property @{
                Action       = $Action
                Selected     = $Service.Selected
                Error        = $ErrorMessages[1]
                ServiceName  = $Service.ServiceName
                DisplayName  = $Service.DisplayName
                ServiceState = $Service.ServiceState
                StartMode    = $Service.StartMode
            }
            $FailedServices = $FailedServices + $FailedService
        }
        $SCounter ++
    }
    
    If ($FailedServices.Count -gt 0) {
        If (($GlobalFilePaths.Application.IndexOf('FailedServicesFile')) -gt -1 -and ($GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('FailedServicesFile'))).FilePath) -ne "") {
            $FailedServicesFile = $GlobalFilePaths.Item(($GlobalFilePaths.Application.IndexOf('FailedServicesFile'))).FilePath
        }
        Else {
            $FailedServicesFile = 'C:\Temp\BattleNet_FailedServices.txt'
        }
        
        If (Test-Path $FailedServicesFile) { Remove-Item $FailedServicesFile }
        $FailedServices | Export-Csv -Path $FailedServicesFile -Force -NoClobber -Encoding ASCII -Delimiter "," -NoTypeInformation
    }
    $Scounter = 1
    Return $FailedServices
}
Function Reset-ServiceConfig {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $ConfigService)
    
    $ServiceName = $ConfigService.ServiceName
    $CurrentService = Get-WmiObject -Query "Select * From Win32_Service Where Name='$ServiceName'"
    
    Try {
        If ($ConfigService.StartMode -ne $CurrentService.StartMode) { 
            Set-Service $CurrentService.Name -StartupType $ConfigService.StartMode -ErrorAction Stop -Confirm:$false | Out-Null
            Write-Color -Text "Startmode: ", $ConfigService.StartMode, " - " -ForegroundColor White, Green, White -NoNewline
        }
        If ($ConfigService.ServiceState -eq $CurrentService.State) { 
            Start-Service -Name $CurrentService.Name -Confirm:$false -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
            Write-Color -Text "Status: ", $ConfigService.ServiceState, " - " -ForegroundColor White, Green, White -NoNewline
        }
    }
    Catch {
        Process-Error -CaughtError $_
        Return $false
    }
    Return $True
}
Function Compare-Services {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $GlobalServices, 
        [Parameter(Mandatory=$True, Position=2)][ValidateSet("Details", "Matches", "Mismatches")]
        [String] $Report)

    $ServiceState = @()
    $ServiceDetailsProperties = @(
        "ConfigDisplayName"
        "ConfigServiceState"
        "ConfigStartMode"
        "ConfigServiceName"
        "CurrentDisplayName"
        "CurrentServiceState"
        "CurrentStartMode"
        "CurrentServiceName")
    $ServiceMatchDetailsProperties = @(
        "Name"
        "DisplayName"
        "ServiceState"
        "StartMode"
        "ServiceName")
    $ServiceMisMatchDetailsProperties = @(
        "Name"
        "Mismatches"
        "ConfigSetting"
        "CurrentSetting")
    For ($i = 0; $i -lt $GlobalServices.Count; $i ++) {
        Write-Color -Text "Getting Service Details for ", $GlobalServices[$i].DisplayName, " - " -ForegroundColor White, Yellow, White -NoNewLine
        $ServiceName = $GlobalServices[$i].ServiceName
        $SystemService = Get-WmiObject -Query "Select * From Win32_Service Where Name='$ServiceName'"
        $CurrentService = New-Object -TypeName PSObject -Property @{
            DisplayName  = $SystemService.DisplayName
            ServiceState = $SystemService.State
            StartMode    = $SystemService.StartMode
            ServiceName  = $SystemService.Name
        }
        Switch ($Report) {
            "Details" {
                $ServiceDetails = New-Object -TypeName PSObject -Property @{
                    ConfigDisplayName   = $GlobalServices[$i].DisplayName
                    ConfigServiceState  = $GlobalServices[$i].ServiceState
                    ConfigStartMode     = $GlobalServices[$i].StartMode
                    ConfigServiceName   = $GlobalServices[$i].ServiceName
        
                    CurrentDisplayName  = $CurrentService.DisplayName
                    CurrentServiceState = $CurrentService.Status
                    CurrentStartMode    = $CurrentService.StartMode
                    CurrentServiceName  = $CurrentService.ServiceName
                }
                $ServiceState = $ServiceState + ($ServiceDetails | Select $ServiceDetailsProperties)
            }
            "Matches" {
                If ($GlobalServices[$i].DisplayName  -eq $CurrentService.DisplayName)  { $DisplayNameMatch = $True }  Else { $DisplayNameMatch = $False }
                If ($GlobalServices[$i].ServiceState -eq $CurrentService.ServiceState) { $ServiceStateMatch = $True } Else { $ServiceStateMatch = $False }
                If ($GlobalServices[$i].StartMode    -eq $CurrentService.StartMode)    { $StartModeMatch = $True }    Else { $StartModeMatch = $False }
                If ($GlobalServices[$i].ServiceName  -eq $CurrentService.ServiceName)  { $ServiceNameMatch = $True }  Else { $ServiceNameMatch = $False }
                If (($DisplayNameMatch -eq $True) -and ($ServiceStateMatch -eq $True) -and ($StartModeMatch -eq $True) -and ($ServiceNameMatch -eq $True)) {
                    $ServiceMatchDetails = New-Object -TypeName PSObject -Property @{
                        Name         = $GlobalServices[$i].DisplayName
                        DisplayName  = $DisplayNameMatch
                        ServiceState = $ServiceStateMatch
                        StartMode    = $StartModeMatch
                        ServiceName  = $ServiceNameMatch
                    } 
                    $ServiceState = $ServiceState + ($ServiceMatchDetails | Select $ServiceMatchDetailsProperties)
                }
            }
            "Mismatches" {
                $MisMatchItems = @()
                If ($GlobalServices[$i].DisplayName  -ne $CurrentService.DisplayName)  { $MisMatchItems = $MisMatchItems + 'DisplayName' }
                If ($GlobalServices[$i].ServiceState -ne $CurrentService.ServiceState) { $MisMatchItems = $MisMatchItems + 'ServiceState' }
                If ($GlobalServices[$i].StartMode    -ne $CurrentService.StartMode)    { $MisMatchItems = $MisMatchItems + 'StartMode' }
                If ($GlobalServices[$i].ServiceName  -ne $CurrentService.ServiceName)  { $MisMatchItems = $MisMatchItems + 'ServiceName' }
                If ($MisMatchItems.Count -gt 0) {
                    ForEach ($MisMatchError in $MisMatchItems) {
                        $ServiceMisMatchDetails = New-Object -TypeName PSObject -Property @{
                            Name           = $GlobalServices[$i].DisplayName
                            Mismatches     = $MisMatchError
                            ConfigSetting  = $GlobalServices[$i].$MisMatchError
                            CurrentSetting = $CurrentService.$MisMatchError
                        } 
                        $ServiceState = $ServiceState + ($ServiceMisMatchDetails | Select $ServiceMisMatchDetailsProperties)
                    }
                }
            }
        }
        Write-Color -Text "Complete" -ForegroundColor Green
    }
    If ($ServiceState.Count -le 0) {
        $ServiceState = 'No Results'
    }
    Return $ServiceState
}
Function Reset-ServiceRemotely {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $FilePath)
    Clear-Host
    Write-Host "Importing Services"
    $Services = Import-Csv $FilePath -Delimiter ","
    ForEach ($Service in $Services) {
        Try {
            Write-Host $Service.DisplayName -ForegroundColor Yellow
            $ServiceName = $Service.ServiceName
            Write-Host "Getting remote service"
            $RemoteService = Invoke-Command -ComputerName winamp -ArgumentList $Service.ServiceName -ScriptBlock {Param ($ServiceName); Get-WmiObject -Query "Select * From Win32_Service Where Name='$ServiceName'"} -Credential $Creds
            If ($Service.StartMode -ne $RemoteService.StartMode) {
                Write-host ("Setting Startmode " + $RemoteService.StartMode + " - " + $Service.StartMode)
                Invoke-Command -ComputerName winamp -ArgumentList $Service.ServiceName, $Service.StartMode -ScriptBlock {Param ($Service, $Mode); Set-Service -Name $Service -StartupType $Mode -ErrorAction Stop -WarningAction SilentlyContinue} -Credential $Creds
            
            }
            If ($Service.ServiceState -eq "Running" -and $RemoteService.State -ne "Running") {
                Write-host ("Setting Startmode " + $RemoteService.State + " - " + $Service.ServiceState)
                Invoke-Command -ComputerName winamp -ArgumentList $Service.ServiceName -ScriptBlock {Param ($ServiceName); Start-Service -Name $ServiceName -ErrorAction Stop -WarningAction SilentlyContinue} -Credential $Creds
            }
        }
        Catch {
            $ErrorMessages = (($CaughtError.Exception.GetBaseException()).ToString() -split ": ")
            Write-Host $ErrorMessages[1] -ForegroundColor Red
        }
        Write-Host
    }
}

$ErrorActionPreference = "Stop"
$WarningPreference     = "SilentlyContinue"

Switch ($Function) {
    "Get-ServiceInfo" {
        $ServiceInfo = Get-ServiceInfo
    }
    "Set-DefaultD3Services" {
        Set-DefaultD3Services
    }
    "Process-Services" {
        Switch ($Action) {
            "Start"      { $FailedServices = Process-Services -Action Start }
            "Stop"       { $FailedServices = Process-Services -Action Stop }
            "AdminStart" { $FailedServices = Process-Services -Action AdminStart }
            "AdminStop"  { $FailedServices = Process-Services -Action AdminStop }
        }
    }
    "Compare-Services" {
        Switch ($Report) {
            "Details"    { Compare-Services -GlobalServices $Services -Report Details    | Format-Table -AutoSize }
            "Matches"    { Compare-Services -GlobalServices $Services -Report Matches    | Format-Table -AutoSize }
            "Mismatches" { Compare-Services -GlobalServices $Services -Report Mismatches | Format-Table -AutoSize }
        }
    }
    "Reset-ServiceRemotely" {
        Reset-ServiceRemotely -FilePath $FilePath
    }
}