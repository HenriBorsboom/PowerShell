Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)
    $ErrorActionPreference = "Stop"
    Try {
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch {
        Write-Error $_ 
    }
}

Clear-Host
#$AdminCreds = Get-Credential
$Servers = @(
    "SYSJHBHV1", `
    "SYSJHBHV2", `
    "SYSJHBHV3", `
    "SYSJHBHV4", `
    "SYSJHBHVTR", `
    "SYSJHBHVTR2", `
    "SYSJHBHVTR3", `
    "SYSJHBTESTHV", `
    "SYSJHBTESTHV2", `
    "SYSJHBSTORE", `
    "SYSJHBVMM", `
    "TS-MONITOR")
$Services = @(
    "Microsoft Monitoring Agent", `
    "Microsoft Monitoring Agent APM", `
    "Microsoft Monitoring Agent Audit Forwarding")

$ServiceInfo = @()

For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Color -Text (($i + 1).ToString() + "/" + $Servers.Count.ToString()), " - Getting Services Details - " -Color Cyan, White -NoNewLine
        $Svcinfo = New-Object PSObject -Property @{
            "Server"                                      = $Servers[$i]           
            "Microsoft Monitoring Agent"                  = (Get-Service -DisplayName $Services[0] -ComputerName $Servers[$i] | Select *).StartType
            "Microsoft Monitoring Agent APM"              = (Get-Service -DisplayName $Services[1] -ComputerName $Servers[$i] | Select *).StartType
            "Microsoft Monitoring Agent Audit Forwarding" = (Get-Service -DisplayName $Services[2] -ComputerName $Servers[$i] | Select *).StartType
        }
    $ServiceInfo = $ServiceInfo + $Svcinfo 
    Write-Host "Complete" -ForegroundColor Green
}
$ServiceInfo | Select "Server", "Microsoft Monitoring Agent", "Microsoft Monitoring Agent APM", "Microsoft Monitoring Agent Audit Forwarding"