Function Start-CHKDSK {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $DriveLetter, `
        [Parameter(Mandatory=$False, Position=2)][ValidateSet ('Online', 'Offline', 'Full')]
        [String] $Mode
    )

    $ChkdskList = @()
    Switch ($Mode) {
        'Online' {
            $ChkdskList += ,('/scan')
            $ChkdskList += ,('/scan', '/i')
            $ChkdskList += ,('/scan', '/i', '/c')
            $ChkdskList += ,('/scan', '/r', '/c')
            $ChkdskList += ,('/scan', '/i', '/r', '/c')
        }
        'Offline' {
            $ChkdskList += ,('/scan', '/x')
            $ChkdskList += ,('/scan', '/x', '/r')
        }
        'Full' {
            $ChkdskList += ,('/scan')
            $ChkdskList += ,('/scan', '/i')
            $ChkdskList += ,('/scan', '/i', '/c')
            $ChkdskList += ,('/scan', '/r', '/c')
            $ChkdskList += ,('/scan', '/i', '/r', '/c')
            $ChkdskList += ,('/scan', '/x')
            $ChkdskList += ,('/scan', '/x', '/r')
        }
        Default {
            $ChkdskList += ,('/scan')
            $ChkdskList += ,('/scan', '/i')
            $ChkdskList += ,('/scan', '/i', '/c')
            $ChkdskList += ,('/scan', '/r', '/c')
            $ChkdskList += ,('/scan', '/i', '/r', '/c')
        }
    }
    
    $Details = @()
    ForEach ($Command in $ChkdskList) {
        Write-Host (((Get-Date) -f "HH:mm:ss") + " - Scanning " + $Driveletter + " with " + $Command)
        $StartDate = Get-Date
        chkdsk $Command $DriveLetter | Out-Null
        $Duration = ((Get-Date) - $StartDate) -f 'HH:mm:ss'
        $Details += (New-Object -TypeName PSObject -Property @{
            Command = $Command
            DriveLetter = $DriveLetter
            Duration = $Duration
        }) | Select-Object DriveLetter, Command, Duration
        Write-Host (((Get-Date) -f "HH:mm:ss") + " - Scanning " + $Driveletter + " with " + $Command + " completed in " + $Duration)
    }
    Return $Details
}