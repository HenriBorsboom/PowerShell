Function Sync-Scripts {
    Param (
        [Parameter(Mandatory = $False)][ValidateSet('Desktop', 'Laptop')]
        [String] $Source, `
        [Parameter(Mandatory = $False)]
        [Switch] $Laptop, `
        [Parameter(Mandatory = $False)]
        [Switch] $Desktop)

    If ($env:COMPUTERNAME -eq "Winamp") {
        $DesktopSource = 'C:\Users\Slash\Documents\Scripts\PowerShell'
        $LaptopSource  = '\\192.168.0.105\c$\Users\henri\Scripts\Powershell'
    }
    ElseIf ($env:COMPUTERNAME -eq "WORKSTATION01") {
        $DesktopSource = '\\192.168.0.103\C\Users\Slash\Documents\Scripts\PowerShell'
        $LaptopSource  = 'C:\Users\henri\Scripts\Powershell'
    }
    
    Switch ($Source) {
        'Laptop' { 
            robocopy /s /zb /r:1 /w:1 /copy:dat /v $LaptopSource $DesktopSource
            #Write-host ("robocopy /s /zb /r:1 /w:1 /copy:dat /v $LaptopSource $DesktopSource")
        }
        'Desktop' {
            robocopy /s /zb /r:1 /w:1 /copy:dat /v $DesktopSource $LaptopSource
            #Write-host ("robocopy /s /zb /r:1 /w:1 /copy:dat /v $DesktopSource $LaptopSource")
        }
    }
    #Return $true
    Switch ($true) {
        $Laptop { 
            robocopy /s /zb /r:1 /w:1 /copy:dat /v $LaptopSource $DesktopSource
            #Write-host ("robocopy /s /zb /r:1 /w:1 /copy:dat /v $LaptopSource $DesktopSource")
        }
        $Desktop {
            robocopy /s /zb /r:1 /w:1 /copy:dat /v $DesktopSource $LaptopSource
            #Write-host ("robocopy /s /zb /r:1 /w:1 /copy:dat /v $DesktopSource $LaptopSource")
        }
    }
    #Return $true
}

Sync-Scripts -Desktop