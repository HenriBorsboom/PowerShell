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
$ErrorActionPreference = 'SilentlyContinue'
Clear-Host

Write-Color -Text 'Getting ', 'Domain Computers', ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
$Computers = Get-DomainComputers
Write-Color -Text 'Complete' -ForegroundColor Green
$BadKB = 'KB3185331'

#ForEach ($Server in $Computers) {
For ($i = 0; $i -lt $Computers.Count; $i ++) {
    Write-Color -Text (($i + 1).ToString() + '/' + $Computers.Count.ToString()), ' - Checking if ', $Computers[$i], ' is online - ' -ForegroundColor Cyan, White, DarkCyan, White -NoNewLine
    If (Test-Connection -ComputerName $Computers[$i] -Count 1 -Quiet) {
        Write-Color -Text 'Checking for ', $BadKB, ' - ' -ForegroundColor White, DarkCyan, White -NoNewLine
        $KBInstalled = Get-WmiObject -Class Win32_QuickFixEngineering -Property HotFixID -ComputerName $Computers[$i] | Where HotFixID -eq $BadKB
        If ($KBInstalled.Count -gt 0) {
            Write-Color -Text 'Found' -ForegroundColor Red
        }
        Else {
            Write-Color -Text 'Not Found' -ForegroundColor Green
        }
    }
    Else {
        Write-Color -Text 'Offline' -ForegroundColor Yellow
    }
}
