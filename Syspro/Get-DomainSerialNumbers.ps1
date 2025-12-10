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

Param ($Server)
$SerialNumber = '560TBG2'
Clear-Host
Write-Color -Text 'Getting computers in ', $env:USERDOMAIN, ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
#$Servers = Get-DomainComputers -Domain $env:USERDOMAIN
#Write-Color -Text $Servers.Count, ' - ', 'Complete' -ForegroundColor Yello, White, Green
#For ($i = 0; $i -lt $Servers.Count; $i ++) {
#    Write-Color -Text (($i + 1).ToString() + '/' + $Servers.Count.ToString()), ' - Checking ', $Servers[$i] -ForegroundColor DarkCyan, White, Yellow -NoNewLine
    Write-Color -Text 'Checking ', $Server -ForegroundColor White, Yellow -NoNewLine
    If (Test-Online -Computer $Server) {
        Write-Color -Text ' Online', ' Getting Serial - ' -ForegroundColor Green, White -NoNewLine
        Try {
            $Result = Get-WmiObject -Class Win32_BIOS -Property SerialNumber -ComputerName $Server -ErrorAction Stop 
            If ($Result.SerialNumber -eq $SerialNumber) { 
                Write-Host 'Found' -ForegroundColor Green
                Break
            }
            Else { 
                Write-Host $Result.SerialNumber
            }
        }
        Catch {
            Write-Host 'WMI Failed' -ForegroundColor Red
        }
    }
    Else {
        Write-Color -Text ' Offline' -ForegroundColor Red
    }
#}