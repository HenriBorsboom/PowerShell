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
Function Write-MenuOption {
    Param (
        [Parameter(Mandatory=$False, Position=0, ParameterSetName="Type")][ValidateSet("Seperator")]
        [String] $Type, `
        [Parameter(Mandatory=$True, Position=1, ParameterSetName="MenuTitle")]
        [String] $StartLine, 
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="MenuTitle")]
        [String] $MenuTitle, `
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="MenuTitle")]
        [String] $EndLine, `
        [Parameter(Mandatory=$True, Position=1, ParameterSetName="MenuItem")]
        [Int]    $Index, 
        [Parameter(Mandatory=$True, Position=2, ParameterSetName="MenuItem")]
        [String] $MenuItem)
    
    Switch ($PSCmdlet.ParameterSetName) {
        "MenuTitle" {
            #Write-Color -Text "--------------", " Sub Menu 1 ", "--------------" -ForegroundColor Green, Cyan, Green
            Write-Host $StartLine -ForegroundColor Green -NoNewline
            Write-Host " $MenuTitle " -ForegroundColor Cyan -NoNewline
            Write-Host $EndLine -ForegroundColor Green
        }
        "MenuItem"  {
            #Write-Color -Text "[", $Index, "]", " $MenuItem" -ForegroundColor DarkCyan, White, DarkCyan, DarkCyan 
            Write-Host "[" -ForegroundColor DarkCyan -NoNewline
            Write-Host $Index -NoNewline
            Write-Host "]" -ForegroundColor DarkCyan -NoNewline
            Write-Host " $MenuItem" -ForegroundColor DarkCyan
        }
        "Type" {
            Switch ($Type) {
                "Seperator" {
                    #Write-Color -Text "----------------------------------------" -ForegroundColor Green 
                    Write-Host "----------------------------------------" -ForegroundColor Green 
                }
            }
            
        }
    }
}
Function Main-Menu {
    $MainMenu = 'X'
    While ($MainMenu -ne '') {
        Clear-Host
        Write-MenuOption -Type Seperator
        Write-MenuOption -StartLine "---------------" -MenuTitle "Main Menu" -EndLine "--------------"
        Write-MenuOption -Type Seperator
        Write-MenuOption -Index 1 -MenuItem "Submenu 1"
        Write-MenuOption -Index 2 -MenuItem "Submenu 2"
        Write-MenuOption -Type Seperator
        $MainMenu = Read-Host "Selection (leave blank to quit)"
        Switch ($MainMenu) {
            1 { Sub-Menu1 }
            2 { Sub-Menu2 }
        }
    }
}
# New-Variable ($test.ToString() + $Index.ToString()) -Value '99'
Function Create-MenuOptions {
    Param (
        [Parameter(Mandatory=$True,  Position=0)][ValidateSet("Seperator", "MenuItem", "MenuTitle")]
        [String] $Type, `
        [Parameter(Mandatory=$False, Position=1)]
        [Int]    $Index, 
        [Parameter(Mandatory=$False, Position=2)]
        [String] $MenuItem)

    $MenuOption = New-Object -TypeName PSObject -Property @{
        Index    = $Index
        MenuItem = $MenuItem
        Type     = $Type
    }
    Return $MenuOption
}
Function Sub-Menu {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [Object[]] $MenuOptions)
    
    $SubMenu = 'X'
    While ($SubMenu -ne '') {
        Clear-Host
        Write-MenuOption -Type Seperator
        Write-MenuOption -StartLine "--------------" -MenuTitle ("Sub Menu " + $Index.ToString()) -EndLine "--------------"
        Write-MenuOption -Type Seperator
        ForEach ($MenuOption in $MenuOptions) {
            If ($MenuOption.Type -eq "Seperator") {
                Write-MenuOption -Type Seperator
            }
            Else {
                Write-MenuOption -Index $MenuOption.Index -MenuItem $MenuOption.MenuItem
            }
        }
        $MenuSelection = Read-Host "Selection (leave blank to quit)"
        Return $MenuSelection
    }
}
Function New-SubMenu {
    $MenuOptions = @()
    $MenuOptions = $MenuOptions + (Create-MenuOptions -Type MenuItem -Index 1 -MenuItem "Say hello")
    $MenuOptions = $MenuOptions + (Create-MenuOptions -Type MenuItem -Index 1 -MenuItem "Say goodbye")
    $MenuOptions = $MenuOptions + (Create-MenuOptions -Type Seperator)

    $MenuAnswer = Sub-Menu -MenuOptions $MenuOptions

    Switch ($MenuAnswer) {
        1 { 
            Write-Host 'Hello!'
            Read-Host "Continue"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
        2 { 
            Write-Host 'Goodbye!'
            Read-Host "Continue"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
    }
    If ($MenuAnswer -ne "x") { New-SubMenu }
}

Function Sub-Menu1 {
    $SubMenu1 = 'X'
    While ($SubMenu1 -ne '') {
        Clear-Host
        Write-MenuOption -Type Seperator
      # Write-Color -Text "---------------", " Main Menu ", "--------------" -ForegroundColor Green, Cyan, Green
      # Write-Color -Text "--------------", " Sub Menu 1 ", "--------------" -ForegroundColor Green, Cyan, Green
        Write-MenuOption -StartLine "--------------" -MenuTitle "Sub Menu 1" -EndLine "--------------"
        Write-MenuOption -Type Seperator
        Write-MenuOption -Index 1 -MenuItem "Say hello"
        Write-MenuOption -Index 2 -MenuItem "Say goodbye"
        Write-MenuOption -Type Seperator
        $SubMenu1 = Read-Host "Selection (leave blank to quit)"
        #$TimeStamp = Get-Date -Uformat %m%d%y%H%M

        Switch ($SubMenu1) {
            1 { 
                Write-Host 'Hello!'
                Read-Host "Continue"
                If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
            }
            2 { 
                Write-Host 'Goodbye!'
                Read-Host "Continue"
                If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
            }
        }
    }
}
Function Sub-Menu2 {
    $SubMenu2 = 'X'
    While ($SubMenu2 -ne '') {
        Clear-Host
        Write-MenuOption -Type Seperator
      # Write-Color -Text "---------------", " Main Menu ", "--------------" -ForegroundColor Green, Cyan, Green
      # Write-Color -Text "--------------", " Sub Menu 2 ", "--------------" -ForegroundColor Green, Cyan, Green
        Write-MenuOption -StartLine "--------------" -MenuTitle "Sub Menu 2" -EndLine "--------------"
        Write-MenuOption -Type Seperator
        Write-MenuOption -Index 1 -MenuItem "Show processes"
        Write-MenuOption -Index 2 -MenuItem "Show PS Version"
        Write-MenuOption -Type Seperator
        $SubMenu2 = Read-Host "Selection (leave blank to quit)"
        #$TimeStamp = Get-Date -Uformat %m%d%y%H%M

        Switch ($SubMenu2) {
            1 { 
                Get-Process
                Read-Host "Continue"
                If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
            }
            2 { 
                $PSVersionTable.PSVersion
                Read-Host "Continue"
                If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
            }
        }
    }
}
New-SubMenu
#Main-Menu