#MenuColors
$SeperatorColor          = [ConsoleColor]::Blue
$MenuItemIndexBlockColor = [ConsoleColor]::Cyan
$MenuItemIndexColor      = [ConsoleColor]::Cyan
$MenuItemTextColor       = [ConsoleColor]::Green
$MenuTitleLineColor      = [ConsoleColor]::Blue
$MenuTitleColor          = [ConsoleColor]::Cyan

#region Create Menu
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
                        StartLine = $null
                        MenuTitle = $MenuTitle
                        EndLine   = $null
                    }
                }
            }
            Return $MenuOption
        }
        "Write"  {
            Switch ($Type) {
                "Seperator" {
                    Write-Color -Text "----------------------------------------" -ForegroundColor $SeperatorColor
                }
                "MenuItem"  {
					Write-Color -Text "[", $Index.ToString(), "] ", $MenuItem -ForegroundColor $MenuItemIndexBlockColor, $MenuItemIndexColor, $MenuItemIndexBlockColor, $MenuItemTextColor
                }
                "MenuTitle" {
                    Write-Color -Text $StartLine, $MenuTitle, $EndLine -ForegroundColor $MenuTitleLineColor, $MenuTitleColor, $MenuTitleLineColor
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
                $Split = [Math]::Round(((38 - $MenuOption.MenuTitle.ToString().Length) / 2), 0)
                $TotalLength = (($Split * 2) + $MenuOption.MenuTitle.ToString().Length)
                If ($TotalLength -lt 38) { 
                    $StartLine = ""
                    For ($i = 0; $i -lt ($Split + 1); $i ++) { $StartLine = $StartLine + "=" }
                    $StartLine = $StartLine + " "
                    $EndLine = " "
                    For ($i = 0; $i -lt $Split; $i ++) { $EndLine = $EndLine + "=" }
                }
                ElseIf ($TotalLength -gt 38) {
                    $StartLine = ""
                    For ($i = 0; $i -lt ($Split - 1); $i ++) { $StartLine = $StartLine + "=" }
                    $StartLine = $StartLine + " "
                    $EndLine = " "
                    For ($i = 0; $i -lt $Split; $i ++) { $EndLine = $EndLine + "=" }
                }
                Else {
                    $StartLine = ""
                    For ($i = 0; $i -lt $Split; $i ++) { $StartLine = $StartLine + "=" }
                    $StartLine = $StartLine + " "
                    $EndLine = " "
                    For ($i = 0; $i -lt $Split; $i ++) { $EndLine = $EndLine + "=" }
                }
                Action-MenuOptions -Action Write -Type MenuTitle -StartLine $StartLine -MenuTitle $MenuOption.MenuTitle -EndLine $Endline
            }
        }
    }
    $MenuAnswer = Read-Host "Option"
    Return $MenuAnswer
}
#endregion
Function Main-Menu {
    #region Draw Menu
    $MenuOptions = @()
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuTitle -MenuTitle "Menu")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 1 -MenuItem "Start Working")
    #$MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 2 -MenuItem "Item 1")
    #$MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 3 -MenuItem "Item 2")
    #$MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    #$MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 4 -MenuItem "Item 3")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type MenuItem -Index 0 -MenuItem "Exit")
    $MenuOptions = $MenuOptions + (Action-MenuOptions -Action Create -Type Seperator)
    $MenuAnswer = New-Menu -MenuOptions $MenuOptions
    #endregion
    #region Menu Answer
    Switch ($MenuAnswer) {
        1 { 
			Start-Working
        }
        2 {
            Write-Host "Item 2"
        }
        3 {
            Write-Host "Item 3"
        } 
        4 {
            Write-Host "Item 4"
        }
    }
    If ($MenuAnswer -eq 0 -or $MenuAnswer -eq "x") {} Else { Main-Menu }
    #endregion
}
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
Function Start-Working {
    $Processes = @()
    # $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 0; Name = ''; Process=''})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 0 ; Name = 'Outlook'    ; Process='C:\Program Files (x86)\Microsoft Office\Office15\OUTLOOK.EXE'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 1 ; Name = 'Firefox'    ; Process='C:\Program Files (x86)\Mozilla Firefox\firefox.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 2 ; Name = 'Chrome'     ; Process='C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 3 ; Name = 'OneNote'    ; Process='C:\Program Files (x86)\Microsoft Office\Office15\ONENOTE.EXE'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 4 ; Name = 'RTChecks'   ; Process='C:\Users\Henri.Borsboom\Desktop\Auto IT\Icons\RT Checks.Exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 5 ; Name = 'GoogleDrive'; Process='C:\Program Files (x86)\Google\Drive\googledrivesync.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 6 ; Name = 'OneDrive'   ; Process='C:\Users\Henri.Borsboom\AppData\Local\Microsoft\OneDrive\OneDrive.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 7 ; Name = 'BlueStacks' ; Process='C:\ProgramData\BlueStacks\Client\BlueStacks.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 8 ; Name = 'Lync'       ; Process='C:\Program Files (x86)\Microsoft Office\root\Office16\lync.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 9 ; Name = 'Opera'      ; Process='C:\Program Files\Opera\launcher.exe'})
    $Processes += ,(New-Object -TypeName PSObject -Property @{ Priority = 10; Name = 'WhatsApp'   ; Process='C:\Users\Henri.Borsboom\AppData\Local\WhatsApp\app-0.2.5863\WhatsApp.exe'})

    For ($i = 0; $i -lt $Processes.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter ($Processes.Count) -Text "Starting ", $Processes[$i].Name, " " -ForegroundColor White, Yellow, White -NoNewLine
        Start-Process -FilePath $Processes[$i].Process
        Start-Wait -Seconds 15 -SpotUpdate
    }
}

Main-Menu