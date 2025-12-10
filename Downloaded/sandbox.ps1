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
Function Delete-LastLine {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
    Write-Host "                                                                                                                                            "
    [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 1)
}

Function Center-Title {
    Param (
        [Parameter(Mandatory=$False, Position=0)][ValidateSet("MenuTitle", "SubTitle", "Seperator")]
        [String]  $Type, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $MenuTitle)
    
    Switch ($Type) {
        "MenuTitle" {
            $Spacer     = " "
            $MenuLength = ($MenuTitle.Length + 2)
            $LineLenght = (($MenuTotalLength - $MenuLength) / 2)
            If ($LineLenght.GetType().Name -eq 'Double') {
                $StartLenght = [Math]::Round($LineLenght,0) + 1
                $EndLength   = [Math]::Round($LineLenght,0) 
            }
            Else { 
                $StartLenght = $LineLenght
                $EndLength   = $LineLenght
            }

            $StartLine = ""
            For ($i = 0; $i -lt $StartLenght; $i ++) {
                $StartLine = $StartLine + "-"
            }
            $EndLine = ""
            For ($i = 0; $i -lt $EndLength; $i ++) {
                $EndLine = $EndLine + "-"
            }

            Write-Color -Text $StartLine, $Spacer, $MenuTitle, $Spacer, $EndLine -ForegroundColor $MenuBarColor, White, $MenuTitleColor, White, $MenuBarColor
        }
        "Seperator" {
            $SeperatorString = ""
            For ($i = 0; $i -lt $MenuTotalLength; $i ++) {
                $SeperatorString = $SeperatorString + "-"
            }

            Write-Color -Text $SeperatorString -ForegroundColor $MenuBarColor
        }
        "SubTitle" {
            $Spacer     = " "
            $MenuLength = ($MenuTitle.Length + 2)
            $LineLenght = (($MenuTotalLength - $MenuLength) / 2)
            If ($LineLenght.GetType().Name -eq 'Double') {
                $StartLenght = [Math]::Round($LineLenght,0) - 1
                $EndLength   = [Math]::Round($LineLenght,0) 
            }
            Else { 
                $StartLenght = $LineLenght
                $EndLength   = $LineLenght
            }

            $StartLine = ""
            For ($i = 0; $i -lt $StartLenght; $i ++) {
                $StartLine = $StartLine + "-"
            }
            $EndLine = ""
            For ($i = 0; $i -lt $EndLength; $i ++) {
                $EndLine = $EndLine + "-"
            }

            Write-Color -Text $StartLine, $Spacer, $MenuTitle, $Spacer, $EndLine -ForegroundColor $MenuBarColor, White, $MenuSubTitleColor, White, $MenuBarColor
        }
        
    }
}
Function Action-MenuOptions {
    Param (
        [Parameter(Mandatory=$True,  Position=0)][ValidateSet("Create", "Write")]
        [String] $Action, `
        [Parameter(Mandatory=$True,  Position=0)][ValidateSet("Seperator", "MenuItem", "MenuTitle","SubTitle")]
        [String] $Type, `
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Index, 
        [Parameter(Mandatory=$False, Position=2)]
        [String] $MenuItem)
    
    Switch ($Action) {
        "Create" {
            Switch ($Type) {
                "Seperator" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "Seperator"
                        Index     = $null
                        MenuItem  = $null
                    }
                }
                "MenuItem" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "MenuItem"
                        Index     = $Index.ToString()
                        MenuItem  = $MenuItem
                    }
                }
                "MenuTitle" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "MenuTitle"
                        Index     = $null
                        MenuItem  = $MenuItem
                    }
                }
                "SubTitle" {
                    $MenuOption = New-Object -TypeName PSObject -Property @{
                        Type      = "SubTitle"
                        Index     = $null
                        MenuItem  = $MenuItem
                    }
                }
            }
            Return $MenuOption
        }
        "Write"  {
            Switch ($Type) {
                "Seperator" {
                    Center-Title -Type Seperator
                }
                "MenuItem"  {
                    Write-Color -Text "[", $Index.ToString(), "]", " $MenuItem" -ForegroundColor $MenuItemHolderColor, $MenuItemIndexColor, $MenuItemHolderColor, $MenuItemColor
                }
                "MenuTitle" {
                    Center-Title -Type Seperator
                    Center-Title -Type MenuTitle -MenuTitle $MenuItem
                    Center-Title -Type Seperator
                }
                "SubTitle" {
                    Center-Title -Type SubTitle -MenuTitle $MenuItem
                }
            }
        }
    }
}
Function New-Menu {
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
                Action-MenuOptions -Action Write -Type MenuTitle -MenuItem $MenuOption.MenuItem
            }
            "SubTitle" {
                Action-MenuOptions -Action Write -Type SubTitle -MenuItem $MenuOption.MenuItem
            }
        }
    }
    $MenuSelection = Read-Host "Selection (leave blank to quit)"
    Return $MenuSelection
}
Function MenuSelection {
    $CursorLeft = [System.Console]::CursorLeft
    $CursorTop  = [System.Console]::CursorTop

    #While (!$done) {
    If ($rui.KeyAvailable) {
        $key = $rui.ReadKey()
        If ($key.virtualkeycode -eq -27) { $done=$true }
        If ($key.keydown) { 
            #If ($key.virtualkeycode -eq 37) { $dir=0 } # Left
            If ($key.virtualkeycode -eq 38) { [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  - 2) } # Up
            #If ($key.virtualkeycode -eq 39) { $dir=2 } # Right
            If ($key.virtualkeycode -eq 40) { [System.Console]::SetCursorPosition($CursorLeft ,$CursorTop  + 1) } # Down
            Write-Host "         " -BackgroundColor Black
        }
    }
    #DrawTheApple;
    #DrawTheSnake;
    #CheckWallHits;
    #CheckSnakeBodyHits;
    #CheckAppleHit;
    
    #Start-Sleep -Milliseconds 100
  
    #$score += $tailLength;
    #} 
}
Function Main-Menu {
    #region Draw Menu
    $MenuOptions = @()
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -MenuItem "Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 1 -MenuItem "Launch Diablo 3 Retails")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 2 -MenuItem "Launch Diablo 3 Public Test Realm")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 3 -MenuItem "Launch Battle.Net")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type SubTitle -MenuItem "Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 4 -MenuItem "Stop Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 5 -MenuItem "Start Services")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 6 -MenuItem "Services Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type SubTitle -MenuItem "Processes")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 7 -MenuItem "Stop Processes")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 8 -MenuItem "Processes Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type SubTitle -MenuItem "Transcripts")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 9 -MenuItem "Transcripts")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 0 -MenuItem "Exit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuAnswer = New-Menu -MenuOptions $MenuOptions
    #endregion
    Switch ($MenuAnswer) {
        1 { 
            $ReturnValue = & $LauncherScript -Action LaunchD3
            If ($ReturnValue -eq "Exit") { $MenuAnswer = 0 }
        } # Launch Diablo 3 Retails
        2 {
            $ReturnValue = & $LauncherScript -Action LaunchPTR
            If ($ReturnValue -eq "Exit") { $MenuAnswer = 0 }
        } # Launch Diablo 3 Public Test Realm
        3 {
            $ReturnValue = & $LauncherScript -Action Battle.Net
            If ($ReturnValue -eq "Exit") { $MenuAnswer = 0 }
        } # Launch Battle.Net
        4 {
            $ReturnedServices = & $ServicesScript -Function Process-Services -Action Stop -Services $GlobalServices -FailedServices $GlobalFailedServices
        } # Stop Services
        5 {
            $ReturnedServices = & $ServicesScript -Function Process-Services -Action Start -Services $GlobalServices -FailedServices $GlobalFailedServices
        } # Start Services
        6 {
            Services-Menu
        } # Services Menu
        7 {
            & $ApplicationsScript -GlobalProcesses $GlobalProcesses -Report Failure
        } # Stop Processes
        8 {
            Processes-Menu
        } # Processes Menu
        9 {
            Transcripts-Menu
            #$MenuAnswer = 0
        } # Transcripts Menu
    }
    If ($MenuAnswer -eq 0 -or $MenuAnswer -eq "x") {} Else { Main-Menu }
}
    [Int]          $MenuTotalLength     = 50          # ------- Menu ------
    [ConsoleColor] $MenuBarColor        = "Green"     # ----------
    [ConsoleColor] $MenuTitleColor      = "Cyan"      # Menu
    [ConsoleColor] $MenuSubTitleColor   = "Gray"      # Sub Title
    [ConsoleColor] $MenuItemHolderColor = "DarkCyan"  # []
    [ConsoleColor] $MenuItemIndexColor  = "Yellow"    # x
    [ConsoleColor] $MenuItemColor       = "White"     # Menu Item
Main-Menu