


#region Global Variables
#region Colors
$MyColors = @{}
$MyColors.Add("Text",      ([ConsoleColor]::White))
$MyColors.Add("Value",     ([ConsoleColor]::Cyan))
$MyColors.Add("Warning",   ([ConsoleColor]::Yellow))
$MyColors.Add("Error",     ([ConsoleColor]::Red))
$MyColors.Add("MenuLine",  ([ConsoleColor]::Green))
$MyColors.Add("MenuTitle", ([ConsoleColor]::Cyan))
$MyColors.Add("MenuItem",  ([ConsoleColor]::DarkCyan))
$MyColors.Add("Seperator", ([ConsoleColor]::Green))

#endregion
#region vCenters
$vCenters = @()
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.5.254'   ; CommonName = 'EOH Midrand Waterfall'; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.33.8'    ; CommonName = 'EOH PE'               ; Username = 'root'  ; Password = 'P@ssw0rd'  })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.130.5'   ; CommonName = 'EOH ERS'              ; Username = 'root'  ; Password = 'EohAbacus!'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.144.27'  ; CommonName = 'EOH Pinmill'          ; Username = 'root'  ; Password = 'con42esx05'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.169.5'   ; CommonName = 'EOH Health'           ; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.172.11'  ; CommonName = 'PTA R21'              ; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.207.11'  ; CommonName = 'Alpine (ECI)'         ; Username = 'root'  ; Password = 'Fro0ple'   })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.238.11'  ; CommonName = 'Autospec'             ; Username = 'root'  ; Password = 'Fro0ple.'  })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.9.2'     ; CommonName = 'EOH KZN'              ; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.17.11'   ; CommonName = 'KZN Gridey'           ; Username = 'root'  ; Password = 'Fro0ple.'  })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.20.11'   ; CommonName = 'Armstrong'            ; Username = 'root'  ; Password = 'Fro0ple'   })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.11'    ; CommonName = 'EOH BT Cape Town'     ; Username = 'root'  ; Password = 'password'  })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.12'    ; CommonName = 'EOH Cape Town'        ; Username = 'root'  ; Password = 'password'  })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.4.15'    ; CommonName = 'More SBT'             ; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.17.11'   ; CommonName = 'EOH-CLEARCPT-VHS1'    ; Username = 'root'  ; Password = 'Fro0ple'   })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.4.100'  ; CommonName = 'Gilloolys'            ; Username = 'domain'; Password = ''          })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.6.16'   ; CommonName = 'EOH FIN'              ; Username = 'root'  ; Password = 'Passw00rd' })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.180.35' ; CommonName = 'Amethyst'             ; Username = 'domain'; Password = ''          })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.5.230'  ; CommonName = 'Teraco'               ; Username = 'domain'; Password = ''          })
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.255.110'; CommonName = 'IMSSD'                ; Username = 'domain'; Password = ''          })
$Properties = @('IPAddress', 'CommonName', 'Username', 'Password')
#endregion
#endregion

#region Menu Functions
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
            Write-Host $StartLine -ForegroundColor $MyColors.MenuLine -NoNewline
            Write-Host " $MenuTitle " -ForegroundColor $MyColors.MenuTitle -NoNewline
            Write-Host $EndLine -ForegroundColor $MyColors.MenuLine
        }
        "MenuItem"  {
            Write-Host "[" -ForegroundColor $MyColors.MenuItem -NoNewline
            Write-Host $Index -NoNewline
            Write-Host "]" -ForegroundColor $MyColors.MenuItem -NoNewline
            Write-Host " $MenuItem" -ForegroundColor $MyColors.MenuItem
        }
        "Type" {
            Switch ($Type) {
                "Seperator" {
                    Write-Host "----------------------------------------" -ForegroundColor $MyColors.Seperator
                }
            }
            
        }
    }
}
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
#endregion
Function Sub-Menu {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [Object[]] $MenuOptions)
    
    $SubMenu = 'X'
    While ($SubMenu -ne '') {
        Clear-Host
        Write-MenuOption -Type Seperator
        Write-MenuOption -StartLine "--------------" -MenuTitle "Sub Menu" -EndLine "--------------"
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

New-SubMenu