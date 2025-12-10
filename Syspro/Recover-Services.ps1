Param (
    [Parameter(Mandatory=$True, Position=0)]
    [String] $Server)

$ErrorActionPreference = 'Stop'
$WarningPreference = 'SilentlyContinue'

Function Recover-Services {
    Param (
        [Parameter(Mandatory=$True, Position=0)]
        [String] $Server)

    Write-Host "Execution on $Server" -ForegroundColor Yellow
    Write-Host "Getting Automatic Services that are stopped - " -NoNewline
    Try {
        $Services = Get-WmiObject -Query "Select * from Win32_Service where startmode = 'auto' and state <> 'Running'" -ComputerName $Server -ErrorAction Stop
        Write-Host ($Services.Count.ToString() + " Found")
    }
    Catch {
        Write-Host "0 Found" -ForegroundColor Green
        Return
    }
    For ($i = 0; $i -lt $Services.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Services.Count.ToString() + ' Starting ' + $Services[$i].DisplayName + ' - ') -NoNewline
        Invoke-Command -ComputerName $Server -ArgumentList $Services[0] -ScriptBlock { Param ($Service); Start-Service $Service.Name }
        Write-Host "Complete"
    }
}
Clear-Host
Recover-Services -Server $Server