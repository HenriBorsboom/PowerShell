# Notes:
# Removed sentive information in strings and replaced with '<common descriptive info>'
# Replace the '' and the information inside with environment information

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
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x,$y - 1)
        $String = ""
        For ($i = 0; $i -lt $pswindow.windowsize.Width; $i ++) {
            $String = ($String + " ")
        }
    
        Write-Host $String 
        [Console]::SetCursorPosition($x,$y -1)
    }
}
Function Get-TotalTime {
    Param(
        [Parameter(Mandatory = $True,  Position = 1)]
        [DateTime] $StartTime, `
        [Parameter(Mandatory = $True,  Position = 2)]
        [DateTime] $EndTime)

    $Duration = New-TimeSpan -Start $StartTime -End $EndTime

    $TotalSeconds = $Duration.TotalSeconds
    $TimeSpan =  [TimeSpan]::FromSeconds($TotalSeconds)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $TimeSpan)
    Return $ReturnVariable
}
Function Get-DomainComputers {
    Param (
        [Parameter(Mandatory = $False,  Position = 1)]
        [String] $Domain = $env:USERDOMAIN)

    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter { ObjectClass -eq "computer" }
    $Servers = $Servers | Sort Name
    $Servers = $Servers.Name

    Return $Servers    
}
Function Get-RemoteRegistryDetails {
    Param(
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Computer, `
        [Parameter(Mandatory = $True, Position = 2)][ValidateSet("ClassesRoot", "CurrentConfig", "CurrentUser", "DynData", "LocalMachine", "PerformanceData", "Users")]
        [String] $Hive, `
        [Parameter(Mandatory = $True, Position = 3)]
        [String] $Key, `
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Value)

    Try {
        $Registry    = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $Computer)
        $RegistryKey = $Registry.OpenSubKey($Key) # $Registry.OpenSubKey("SOFTWARE\\Microsoft\\Virtual Machine\\Guest\\Parameters")
        $Value       = $RegistryKey.GetValue($Value)
    }
    Catch { $Value = "Not found" }
    Return $Value
}
Function Wait {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int64] $Duration)

    For ($Tick = 0; $Tick -lt $Duration; $Tick ++) {
        Write-Host "." -NoNewline
        Sleep 1
    }
    Write-Host ""
}
Function Test-Online {
    Param (
        [Parameter(Mandatory=$True,  Position=1)]
        [String] $Computer)

    If (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
        Return $True
    }
    Else {
        Return $False
    }
}
Function Get-LastBootTime {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Computer)

    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property LastBootupTime | Select-Object @{label='LastBootupTime';expression={$_.ConvertToDateTime($_.LastBootupTime)}}
    
    $Details = New-Object PSObject -Property @{
        "Computer" = $Computer
        "BootTime" = $Installed.LastBootupTime
    }

    Return $Details
}
Function Delete-Spot {
    If ($Host.Name -notlike '*ISE*') {
        $PShost = Get-Host
        $pswindow = $pshost.ui.rawui

        $x = [Console]::CursorLeft
        $y = [Console]::CursorTop
        [Console]::SetCursorPosition($x, $y)

        $CursorIndex = @('-', '\', '|', '/')
        If ($Global:CurrentSpot -eq $null)              { $Global:CurrentSpot = 0 }
        If ($Global:CurrentSpot -gt $CursorIndex.Count) { $Global:CurrentSpot = 0 }
        Write-Host $CursorIndex[$Global:CurrentSpot] -NoNewline
        $Global:CurrentSpot ++
        [Console]::SetCursorPosition($x, $y)
        Write-Host "" -NoNewline
    }
}
