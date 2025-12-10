Function Main-Menu {
    $MainMenu = 'X'
    While ($MainMenu -ne '') {
        Clear-Host
        Write-Host "`n`t`t My Script`n"
        Write-Host "Main Menu" -ForegroundColor Cyan
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host " Submenu1" -ForegroundColor DarkCyan
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host " Submenu2" -ForegroundColor DarkCyan
        $MainMenu = Read-Host "`nSelection (leave blank to quit)"
        # Launch submenu1
        If ($MainMenu -eq 1) {
            Sub-Menu1
        }
        # Launch submenu2
        If ($MainMenu -eq 2) {
            Sub-Menu2
        }
    }
}
Function Sub-Menu1 {
    $SubMenu1 = 'X'
    While ($SubMenu1 -ne '') {
        Clear-Host
        Write-Host "`n`t`t My Script`n"
        Write-Host "Sub Menu 1" -ForegroundColor Cyan 
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host -ForegroundColor DarkCyan " Say hello"
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host " Say goodbye" -ForegroundColor DarkCyan 
        $SubMenu1 = Read-Host "`nSelection (leave blank to quit)"
        $TimeStamp = Get-Date -Uformat %m%d%y%H%M
        # Option 1
        If ($SubMenu1 -eq 1) {
            Write-Host 'Hello!'
            # Pause and wait for input before going back to the menu
            Write-Host "`nScript execution complete." -ForegroundColor DarkCyan
            Write-Host "`nPress any key to return to the previous menu"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
        # Option 2
        If ($SubMenu1 -eq 2){
            Write-Host 'Goodbye!'
            # Pause and wait for input before going back to the menu
            Write-Host "`nScript execution complete." -ForegroundColor DarkCyan
            Write-Host "`nPress any key to return to the previous menu"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
    }
}
Function Sub-Menu2 {
    $SubMenu2 = 'X'
    While ($SubMenu2 -ne '') {
        Clear-Host
        Write-Host "`n`t`t My Script`n"
        Write-Host "Sub Menu 2" -ForegroundColor Cyan
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "1"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host " Show processes" -ForegroundColor DarkCyan 
        Write-Host -ForegroundColor DarkCyan -NoNewline "`n["; Write-Host -NoNewline "2"; Write-Host -ForegroundColor DarkCyan -NoNewline "]"; `
            Write-Host " Show PS Version" -ForegroundColor DarkCyan
        $SubMenu2 = Read-Host "`nSelection (leave blank to quit)"
        $timeStamp = Get-Date -Uformat %m%d%y%H%M
        # Option 1
        if($SubMenu2 -eq 1){
            Get-Process
            # Pause and wait for input before going back to the menu
            Write-Host "`nScript execution complete." -ForegroundColor DarkCyan
            Write-Host "`nPress any key to return to the previous menu"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
        # Option 2
        if($SubMenu2 -eq 2){
            $PSVersionTable.PSVersion
            # Pause and wait for input before going back to the menu
            Write-Host "`nScript execution complete." -ForegroundColor DarkCyan
            Write-Host "`nPress any key to return to the previous menu"
            If ($Host.Name -notlike '*ISE*') { [void][System.Console]::ReadKey($true) }
        }
    }
}
Main-Menu