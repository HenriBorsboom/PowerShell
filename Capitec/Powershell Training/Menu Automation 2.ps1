#region Production
<#
Param (
    [Parameter(Mandatory=$True,  Position=1)]
    [Object[]] $GlobalFilePaths, `
    [Parameter(Mandatory=$True,  Position=2)]
    [Object[]] $GlobalServices, `
    [Parameter(Mandatory=$True,  Position=3)]
    [Object[]] $GlobalProcesses, `
    [Parameter(Mandatory=$True,  Position=2)]
    [Object[]] $GlobalFailedServices, `
    [Parameter(Mandatory=$True,  Position=3)]
    [Object[]] $GlobalFailedProcesses, `
    [Parameter(Mandatory=$False, Position=4)]
    [String] $ServicesScript, `
    [Parameter(Mandatory=$False, Position=5)]
    [String] $ApplicationsScript, `
    [Parameter(Mandatory=$False, Position=5)]
    [String] $LauncherScript)
#>
#endregion
#region Debug
#Debug
#<#
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
$ErrorActionPreference = "Stop"
$WarningPreference     = "SilentlyContinue"

$GlobalFilePaths       = Load-Settings -Setting FilePaths
$GlobalServices        = Load-Settings -Setting Services
$GlobalProcesses       = Load-Settings -Setting Processes
$GlobalFailedServices  = Load-Settings -Setting FailedServices
$GlobalFailedProcesses = Load-Settings -Setting FailedProcesses

$ServicesScript        = 'C:\Users\Slash1.Winamp\D3-Services.ps1'
$ApplicationsScript    = 'C:\Users\Slash1.Winamp\D3-Applications.ps1'
$LauncherScript        = 'C:\Users\Slash1.Winamp\D3-Launcher.ps1'
#>
#endregion

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
Function Action-MenuOptions {
    Param (
        [Parameter(Mandatory=$True,  Position=0)][ValidateSet("Create", "Write")]
        [String] $Action, `
        [Parameter(Mandatory=$True,  Position=0)][ValidateSet("Seperator", "MenuItem", "MenuTitle")]
        [String] $Type, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Index, 
        [Parameter(Mandatory=$False, Position=2)]
        [String] $MenuItem, `
        [Parameter(Mandatory=$False, Position=3)]
        [String] $StartLine, 
        [Parameter(Mandatory=$False, Position=4)]
        [String] $MenuTitle, `
        [Parameter(Mandatory=$False, Position=5)]
        [String] $EndLine)
    
    Switch ($Action) {
        "Create" {
            Switch ($Type) {
                "Seperator" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "Seperator"
                        Index     = $null
                        MenuItem  = $null
                        StartLine = $null
                        MenuTitle = $null
                        EndLine   = $null
                    }
                }
                "MenuItem" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "MenuItem"
                        Index     = $Index.ToString()
                        MenuItem  = $MenuItem
                        StartLine = $null
                        MenuTitle = $null
                        EndLine   = $null
                    }
                }
                "MenuTitle" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "MenuTitle"
                        Index     = $null
                        MenuItem  = $null
                        StartLine = $StartLine
                        MenuTitle = $MenuTitle
                        EndLine   = $EndLine
                    }
                }
            }
            Return $MenuOption
        }
        "Write"  {
            Switch ($Type) {
                "Seperator" {
                    #Write-Color -Text "----------------------------------------" -ForegroundColor Green 
                    Write-Host "----------------------------------------" -ForegroundColor Green 
                }
                "MenuItem"  {
                    #Write-Color -Text "[", $Index, "]", " $MenuItem" -ForegroundColor DarkCyan, White, DarkCyan, DarkCyan 
                    Write-Host "[" -ForegroundColor DarkCyan -NoNewline
                    Write-Host $Index.ToString() -NoNewline
                    Write-Host "]" -ForegroundColor DarkCyan -NoNewline
                    Write-Host " $MenuItem" -ForegroundColor DarkCyan
                }
                "MenuTitle" {
                    #Write-Color -Text "--------------", " Sub Menu 1 ", "--------------" -ForegroundColor Green, Cyan, Green
                    Write-Host $StartLine -ForegroundColor Green -NoNewline
                    Write-Host $MenuTitle -ForegroundColor Cyan -NoNewline
                    Write-Host $EndLine -ForegroundColor Green
                }
            }
        }
    }
}
Function New-Menu {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [Object[]] $MenuOptions)
    Function Create-Menu {
        Param (
            [Parameter(Mandatory=$True, Position=0)]
            [Object[]] $MenuOptions)
    
        Clear-Host
        
        ForEach ($MenuOption in $MenuOptions) {
            Switch ($MenuOption.Type) {
                "Seperator" {
                    Action-MenuOptions -Action Write -Type Seperator
                }
                "MenuItem" {
                    Action-MenuOptions -Action Write -Type MenuItem -Index $MenuOption.Index.ToString() -MenuItem $MenuOption.MenuItem
                }
                "MenuTitle" {
                    Action-MenuOptions -Action Write -Type Seperator
                    Action-MenuOptions -Action Write -Type MenuTitle -StartLine $MenuOption.StartLine -MenuTitle $MenuOption.MenuTitle -EndLine $MenuOption.EndLine
                    Action-MenuOptions -Action Write -Type Seperator
                }
            }
        }
        $MenuSelection = Read-Host "Selection (leave blank to quit)"
        Return $MenuSelection
    }

    $MenuAnswer = Create-Menu -MenuOptions $MenuOptions
    Return $MenuAnswer
}

Function Main-Menu {
    #region Draw Menu
    $MenuOptions = @()
  # $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "----------------- " -MenuTitle "Menu" -EndLine " -----------------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "----------------- " -MenuTitle "Menu" -EndLine " -----------------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 1 -MenuItem "Launch Diablo 3 Retails")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 2 -MenuItem "Launch Diablo 3 Public Test Realm")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 3 -MenuItem "Launch Battle.Net")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 4 -MenuItem "Stop Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 5 -MenuItem "Start Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 6 -MenuItem "Services Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 7 -MenuItem "Stop Processes")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 8 -MenuItem "Processes Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 0 -MenuItem "Exit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuAnswer = New-Menu -MenuOptions $MenuOptions
    #endregion
    Switch ($MenuAnswer) {
        1 { 
            Action-Items -Action Stop 
            Start-Diablo -Version Full
        } # Launch Diablo 3 Retails
        2 {
            Action-Items -Action Stop
			Start-Diablo -Version PTR
        } # Launch Diablo 3 Public Test Realm
        3 {
            Start-Process -FilePath $FilePaths.Item(($FilePaths.Application.IndexOf('BattleNetFile'))).FilePath
			& $ApplicationsScript -SingleProcess "Battle.net" -State Start
            & $ApplicationsScript -SingleProcess "Battle.net" -State Close
        } # Launch Battle.Net
        4 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop
            Read-Host "Continue"
        } # Stop Services
        5 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop
            Read-Host "Continue"
        } # Start Services
        6 {
            Services-Menu
        } # Services Menu
        7 {
            & $ApplicationsScript -GlobalProcesses $GlobalProcesses
            Read-Host "Continue"
        } # Stop Processes
        8 {
            Processes-Menu
        } # Processes Menu
    }
    If ($MenuAnswer -eq 0 -or $MenuAnswer -eq "x") {} Else { Main-Menu }
}
Function Services-Menu {
    #region Draw Menu
    $MenuOptions = @()
  # $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "----------------- " -MenuTitle "Menu" -EndLine " -----------------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "--------------- " -MenuTitle "Services" -EndLine " ---------------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 1 -MenuItem " Start Service (Retry Failed)")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 2 -MenuItem " Start Service")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 3 -MenuItem " Start Service and quit (Retry Failed)")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 4 -MenuItem " Start Service and quit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 5 -MenuItem " Stop Services (Retry Failed)")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 6 -MenuItem " Stop Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 7 -MenuItem " Stop Services and quit (Retry Failed)")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 8 -MenuItem " Stop Services and quit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 9 -MenuItem " Compare Services with Details")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 10 -MenuItem "Compare Services with Matches")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 11 -MenuItem "Compare Services with Mismatches")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 12 -MenuItem "Get Current Services Configuration")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 0 -MenuItem "Exit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuAnswer = New-Menu -MenuOptions $MenuOptions
    #endregion
    Switch ($MenuAnswer) {
        1 { 
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action AdminStart
            Read-Host "Continue"
        }  # Start Service (Retry Failed)
        2 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Start
            Read-Host "Continue"
        }  # Start Service
        3 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action AdminStart
            $MenuAnswer = 0
        }  # Start Service and quit (Retry Failed)
        4 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Start
            $MenuAnswer = 0
        }  # Start Service and quit
        5 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action AdminStop
            Read-Host "Continue"
        }  # Stop Services (Retry Failed)
        6 {
            & $ServicesScript -Function Process-Services -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop
            Read-Host "Continue"
        }  # Stop Services
        7 {
            & $ServicesScript -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action AdminStop
            $MenuAnswer = 0
        }  # Stop Services and quit (Retry Failed)
        8 {
            & $ServicesScript -FilePaths $GlobalFilePaths -Services $GlobalServices -FailedServices $GlobalFailedServices -Action Stop
            $MenuAnswer = 0
        }  # Stop Services and quit
        9 {
            & $ServicesScript -Function Compare-Services -Services $GlobalServices -Report Details
            Read-Host "Continue"
        }  # Compare Services with Details
        10 {
            & $ServicesScript -Function Compare-Services -Services $GlobalServices -Report Matches
            Read-Host "Continue"
        } # Compare Services with Matches
        11 {
            & $ServicesScript -Function Compare-Services -Services $GlobalServices -Report Mismatches
            Read-Host "Continue"
        } # Compare Services with Mismatches
        12 {
            #region Services Structure
            <#
            $Services.TotalCount 
            $Services.AutoCount
            $Services.ManualCount
            $Services.DisabledCount
            $Services.Services.DisplayName
            $Services.Services.Name
            $Services.Services.StartMode
            $Services.Services.State
            $Services.AutoService.DisplayName
            $Services.AutoService.Name
            $Services.AutoService.StartMode
            $Services.AutoService.State
            $Services.ManualService.DisplayName
            $Services.ManualService.Name
            $Services.ManualService.StartMode
            $Services.ManualService.State
            $Services.DisabledService.DisplayName
            $Services.DisabledService.Name
            $Services.DisabledService.StartMode
            $Services.DisabledService.State
            #>
            #endregion
            $Services = & $ServicesScript -Function Get-ServiceInfo
            CurrentServices-Menu -Services $Services
        } # Get Current Services Configuration
    }
    If ($MenuAnswer -eq 0 -or $MenuAnswer -eq "x") {} Else { Services-Menu }
}
Function Processes-Menu {

}
Function CurrentServices-Menu {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object[]] $Services)

    $ServicesProperties = @(
        "DisplayName"
        "Name"
        "StartMode"
        "State")

    $MenuOptions = @()
  # $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "----------------- " -MenuTitle "Menu" -EndLine " -----------------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -StartLine "----------- " -MenuTitle "Current Services" -EndLine " -----------")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index $Services.TotalCount.ToString("000")    -MenuItem ": Total Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index $Services.AutoCount.ToString("000")     -MenuItem ": Total Auto")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index $Services.ManualCount.ToString("000")   -MenuItem ": Total Manual")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index $Services.DisabledCount.ToString("000") -MenuItem ": Total Disabled")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 1 -MenuItem "All Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 2 -MenuItem "Auto Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 3 -MenuItem "Manual Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 4 -MenuItem "Disabled Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 0 -MenuItem "Exit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    
    $MenuAnswer = New-Menu -MenuOptions $MenuOptions
    Switch ($MenuAnswer) {
        # All Services
        1 { 
            Clear-Host
            $Services.Services | Select $ServicesProperties
            Write-Host
            Write-Host ("Total Services: " + $Services.TotalCount.ToString() + " - " + "Total Auto: " + $Services.AutoCount.ToString() + " - " + "Total Manual: " + $Services.ManualCount.ToString() + " - " + "Total Disabled: " + $Services.DisabledCount.ToString())
            Read-Host "Continue"
        }
        # Auto Services
        2 {
            Clear-Host
            $Services.AutoService | Select $ServicesProperties
            Write-Host
            Write-Host ("Total Services: " + $Services.TotalCount.ToString() + " - " + "Total Auto: " + $Services.AutoCount.ToString() + " - " + "Total Manual: " + $Services.ManualCount.ToString() + " - " + "Total Disabled: " + $Services.DisabledCount.ToString())
            Read-Host "Continue"
        }
        # Manual Services
        3 {
            Clear-Host
            $Services.ManualService | Select $ServicesProperties
            Write-Host
            Write-Host ("Total Services: " + $Services.TotalCount.ToString() + " - " + "Total Auto: " + $Services.AutoCount.ToString() + " - " + "Total Manual: " + $Services.ManualCount.ToString() + " - " + "Total Disabled: " + $Services.DisabledCount.ToString())
            Read-Host "Continue"
        }
        # Disabled Services
        4 {
            Clear-Host
            $Services.DisabledService | Select $ServicesProperties
            Write-Host
            Write-Host ("Total Services: " + $Services.TotalCount.ToString() + " - " + "Total Auto: " + $Services.AutoCount.ToString() + " - " + "Total Manual: " + $Services.ManualCount.ToString() + " - " + "Total Disabled: " + $Services.DisabledCount.ToString())
            Read-Host "Continue"
        }
    }
    If ($MenuAnswer -eq 0 -or $MenuAnswer -eq "x") {} Else { CurrentServices-Menu -Services $Services }
}

Main-Menu